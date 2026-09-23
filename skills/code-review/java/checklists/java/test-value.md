# Test Value

Apply this gate to every net-new test file, new `@Test` method, and new Spock feature method in the change. Run it before any test style or structure item.

## The gate

For each new test, name the business rule of this change that goes red when the test is removed.

- A named rule of this feature: the test passes the gate. Grade it against the style and structure items.
- No rule, or a rule that only matters during this one change: flag **MEDIUM — propose removal**. Stop grading that test. Suggest where the effort belongs instead: the feature's own behaviour.

Project stance: coverage for its own sake is not a goal. A test earns its place by catching a concrete, recurring failure mode of the code under change: business logic, branching, validation rules, integration seams.

## Low-signal tests (propose removal)

- **Trivial mapping**: `from()` round-trip, getter/setter, field copy through layers, tested in isolation.
- **Framework behaviour**: Hibernate writes a column, Jackson (de)serializes a record.
- **Framework configuration**: the test proves the global setup that every endpoint shares, not the feature. Examples: the shared `ObjectMapper` rejects unknown properties (`FAIL_ON_UNKNOWN_PROPERTIES`), the global exception handler maps `HttpMessageNotReadableException` to 400, default Bean Validation fires on `@Valid`. Signal: a fixture carries an unknown, retired, or non-existent field, and the test expects 400 / `MESSAGE_NOT_READABLE` / a parser error message. This test goes red only when someone edits the global config. It adds nothing to the new payload. Fix: delete the test and its fixture file.

Keep a rejection test when the code under change rejects the field itself, for example a custom validator or an explicit check for a retired field. That rejection is business logic of the feature.

## Keep: the working form

An integration test that drives the new feature through its real endpoint and database and asserts the feature's own data passes the gate. This includes save-then-fetch of a new form across its real branches (two persons, optional sections absent, null coverage). It is the target for testing effort. It is not "X in, X out" plumbing: it proves the new mapping, persistence, and branching work together.

When you suggest a replacement for a removed test, prefer this kind of test: real Postgres (`TestPostgresqlContainer`) + MockMvc over a new unit test.

## Example

Remove (tests global Jackson config, not the form):

```java
@Test
void shouldRejectProTectInformationCarryingAnUnknownField() throws Exception {
  // given
  var proTectFormPayload = TestUtil.readStringFromFile(PROTECT_UNKNOWN_BAG_FIELD_PAYLOAD_PATH);

  // then
  mockMvc
      .perform(post(SAVE_INSURANCE_FORM_PATH)
          .contentType(MediaType.APPLICATION_JSON_VALUE)
          .content(proTectFormPayload))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.errorCode", is(ErrorCode.MESSAGE_NOT_READABLE.getCode())))
      .andExpect(jsonPath("$.errorMessage", containsString(RETIRED_BAG_FIELD)));
}
```

Keep (the working form, both insured persons, real branches):

```java
@Test
void shouldReturnSavedProTectInformationForBothInsuredPersons() throws Exception {
  // given
  var proTectFormPayload = TestUtil.readStringFromFile(PROTECT_TWO_PERSONS_PAYLOAD_PATH);
  saveInsuranceForm(proTectFormPayload);

  // when
  var savedForm = fetchSavedInsuranceForm(proTectFormPayload);

  // then
  savedForm
      .andExpect(status().isOk())
      .andExpect(jsonPath(proTectPath(FIRST_INSURED_PERSON) + ".occupation", is("WORKER")))
      .andExpect(jsonPath(proTectPath(SECOND_INSURED_PERSON) + ".unemploymentCoveragePeriod").value(nullValue()))
      .andExpect(jsonPath(coveragePath(SECOND_INSURED_PERSON) + ".unemployment").value(nullValue()));
      // ... plus the remaining per-person protocol and coverage assertions
}
```

## Missing coverage

Flag missing tests only where the change adds business logic to protect. Pure mapping edits, nullable column adds, record fields that pass through unchanged, and getter/setter additions need no new test. Manual verification is the accepted default for those.
