# Java Test Conventions

The examples come from the reference Spring Boot project. When the project under test has its own base classes or utilities, use those and keep the pattern.

## Structure: Test Cases First, Helpers Last
When opening a test file, developers care about test cases, not helper methods. Structure accordingly:
1. Class fields (mocks, test subjects) at the top
2. `@BeforeEach` setup if needed
3. Test methods (the actual test cases)
4. Private helper/factory methods at the **bottom**

## Sections: //given //when //then
Every test method must have `// given`, `// when`, `// then` comment sections. Omit `// given` only if the test has no setup.

```java
@Test
void shouldRejectInvalidInput() {
    // given
    var input = createInput("invalid");

    // when
    var result = validator.isValid(input, context);

    // then
    assertThat(result).isFalse();
}
```

## @Nested: Only When Multiple Groups Exist
Do NOT add a `@Nested` class if you only have one group. Use `@Nested` when tests naturally split into 2+ groups with different setup (e.g., `WhenRequired` vs `WhenOptional`). Name nested classes descriptively (`WhenRequired`, `WhenCustomMaxLength`).

## Imports: No Full Package Paths
Use imports instead of inline full package paths. Never write `new de.smartinsurtech.annex.lead.request.LeadRequest(...)`, import the class instead.

## Naming
- Test methods: `should` prefix (`shouldRejectNull`, `shouldMapToAllianzOrderRequest`)
- No redundant context in method names that the `@Nested` class already provides

## Capture Results Before Asserting
Separate the action from the assertion by capturing into a variable:
```java
// when
var result = service.process(input);

// then
assertThat(result).isNotNull();
```

## Assertion Libraries
- Project uses both **Hamcrest** and **AssertJ**. Either is acceptable.
- Use static imports for matchers (`assertThat`, `is`, `notNullValue`).

## Test Utilities
- Use `TestUtil.readObjectFromFile()` for loading JSON test fixtures
- Use `TestUtil.createPolicyHolder()` and similar factory methods from existing test utilities
- Use `@SpringBootTestProfile` for tests needing Spring context with H2

## Test Type Selection

**Pure unit test** (no Spring context, < 1 sec):
```java
@ExtendWith(MockitoExtension.class)
class PhoneNumberValidatorTest {
    @Mock private ConstraintValidatorContext context;
    @InjectMocks private PhoneNumberValidator validator;
}
```

**Component test** (H2 in-memory, mocked dependencies):
```java
@SpringBootTestProfile
class OfferPersistenceServiceTest {
    @InjectMocks private OfferPersistenceService service;
    @Mock private AntraegeApiService antraegeApiService;
}
```

**Integration test** (real PostgreSQL via TestContainers):
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@DirtiesContext
@Testcontainers
class OrderPersistenceServiceIntegrationTest extends TestPostgresqlContainer {
    @Autowired private OrderPersistenceService service;
}
```

**E2E test** (full server with mocked external APIs):
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.DEFINED_PORT)
@Testcontainers
@DirtiesContext
@TestPropertySource(properties = {"server.port=8090"})
public class CardifOrderIntegrationTest extends TestPostgresqlContainer {
    @MockitoBean MicrosoftTeamsNotifier microsoftTeamsNotifier;
}
```

**Decision guide**: Pure business logic -> unit test. Spring wiring needed -> component test. Database operations -> integration test. Full HTTP flow -> E2E test.

## Mock Patterns

**Mockito annotation usage**:
- `@Mock` for plain Mockito mocks (unit tests with `@ExtendWith(MockitoExtension.class)`)
- `@MockitoBean` to replace Spring beans in context (integration tests)
- `@MockitoSpyBean` to wrap real bean with spy (partial mocking)
- `@InjectMocks` to auto-wire mocks into service under test
- `@Spy @InjectMocks` for real method calls with spy capability

**Stubbing styles**:
- Standard: `when(...).thenReturn(...)`, `when(...).thenThrow(...)`
- BDD-style: `given(...).willReturn(...)` (from `BDDMockito`)
- Void methods: `doNothing().when(...).method(...)`

**Verification**:
- `verify(...).method(...)` for interaction verification
- `verify(..., times(n))` for call count
- `verifyNoInteractions(...)` for asserting no interactions
- `ArgumentCaptor<T>` for capturing and asserting method arguments

## Database Testing

**TestPostgresqlContainer base class**:
- Provides PostgreSQL 16.1 with container reuse
- `@DynamicPropertySource` injects DB connection details
- `@BeforeEach prepareDatabase()` calls `databaseTestUtil.clear()`

**EntityManager in tests**:
```java
@PersistenceContext private EntityManager em;

em.persist(entity);
em.flush();   // Force write to DB
em.clear();   // Clear first-level cache, force fresh load
```

**DatabaseTestUtil.clear()**: Transactional cleanup of all tables in dependency order. Called in `@BeforeEach` for test isolation.

## Parameterized Tests

```java
@ParameterizedTest
@ValueSource(strings = {"+491721234567", "+48123456789"})
void shouldAcceptValidPhoneNumbers(String phone) { ... }

@ParameterizedTest
@NullSource
void shouldRejectNull(String value) { ... }

@ParameterizedTest
@CsvSource(delimiter = '|', textBlock = """
    true    | true   | 4  | 2
    true    | false  | 2  | 1
""")
void shouldSendCorrectNumberOfOrders(boolean first, boolean second, int send, int save) { ... }
```

## MockMvc Controller Testing

```java
@SpringBootTestProfile
@AutoConfigureMockMvc
class InsuranceFormControllerTest {
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
            .setControllerAdvice(RequestProcessingExceptionHandler.class)
            .build();
    }
}

// With security context:
mockMvc.perform(
    get("/form/insurance/residual-debt/1")
        .with(user("user").authorities(() -> "ANNEX_RSV_INSURANCE_READ"))
).andExpect(status().isOk());
```

## Dynamic Properties for External APIs

```java
@DynamicPropertySource
static void dynamicProperties(DynamicPropertyRegistry registry) {
    registry.add("cardif.url", () -> "http://localhost:8090/test/cardif/order/");
    registry.add("europace.api.antraege_url", () -> "http://localhost:8090/test/antraege");
}
```

## Exception Testing

```java
var exception = assertThrows(
    LoanContractNoContentException.class,
    () -> service.fetchInsuranceForm(loanContract));

assertThat(exception.getStatus(), is(HttpStatus.NO_CONTENT));
```

## Log Verification

```java
var logCaptor = LogCaptor.forClass(OrderHandler.class);
// execute code
// assert log messages via logCaptor
```

## Bean Validation Testing

```java
private static ValidatorFactory validatorFactory;

@BeforeAll
static void setUpFactory() {
    validatorFactory = Validation.buildDefaultValidatorFactory();
}

@AfterAll
static void tearDownFactory() {
    validatorFactory.close();
}

@Test
void shouldPassWithValidAddress() {
    var validator = validatorFactory.getValidator();
    var violations = validator.validate(address);
    assertThat(violations).isEmpty();
}
```

## Test Resource Organization

```
src/test/resources/
├── order/               # Order test data (order.json, coreOrder.json)
├── translator/          # Mapper test data by insurer
│   ├── creditlife/
│   ├── cardif/
│   ├── provinzial/
│   └── allianz/
├── responses/           # Insurer response fixtures by insurer
├── requests/            # Insurer request fixtures
├── entities/            # Database entity fixtures
├── e2e/                 # End-to-end test data
│   ├── offer/
│   └── price/
├── files/               # Binary files (PDFs)
└── validation/          # Validation test fixtures
```

Naming: `<domain><Type><OptionalDetail>.json` (e.g. `creditlifeInsuranceCaseEntity.json`)

## JSON & ObjectMapper in Tests

```java
private ObjectMapper objectMapper;

@BeforeEach
void setUp() {
    objectMapper = JsonMapper.builder()
        .addModule(new JavaTimeModule())
        .build();
}

// Loading fixtures:
var order = (Order) TestUtil.readObjectFromFile("/order/order.json", Order.class);
```

## Reference test files
Before writing a new test class, review 1-2 existing test files in the project to match the current conventions. Good reference files:
- `AllianzOrderMapperTest.java` (simple Spring context test)
- `AntraegeDocumentsRetrieverTest.java` (mock-based test with setup)
- `PriceValidatorTest.java` (pure unit test with //given //when //then)
- `PhoneNumberValidatorTest.java` (parameterized with @Nested groups)
- `CardifOrderIntegrationTest.java` (full E2E with TestContainers)
