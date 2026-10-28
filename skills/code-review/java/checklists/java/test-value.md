# Test Value

Apply this gate to every net-new test file, new `@Test` method, new Spock feature method, and new assertion in an existing test. Run it before any test style or structure item. When you write tests, run it on each test you plan, before you write it: the default is no test.

## The gate

For each new test, name the business rule of this change that goes red when the test is removed.

- A named rule of this feature: the test passes the gate. Grade it against the style and structure items.
- No rule, or a rule that only matters during this one change: flag **MEDIUM — propose removal**. Stop grading that test. Suggest where the effort belongs instead: the feature's own behaviour.

Project stance: coverage for its own sake is not a goal. A test earns its place by catching a concrete, recurring failure mode of the code under change: business logic, branching, validation rules, integration seams.

## Drop-on-sight scan

Ask these in order for each new test or assertion. The first YES fails the gate: drop it, and stop grading it.

1. **Removed concept**: the test names a symbol that the change deleted. It tests nothing and misleads the next reader. (Example: `shouldReturnEmptyMapWhenPayloadCarriesNoBankData` after the bank field left the model.)
2. **Compiler-guaranteed**: the code would not compile if the assertion were false. Examples: a deleted field is absent, an enum constant exists, a record carries a field. (Example: `doesNotHaveJsonPath("$.bankAccount")` after the field was deleted.)
3. **Framework-guaranteed**: Jackson, Hibernate, Lombok, Spring, or the shared global config owns the behaviour. See "Framework configuration" below.
4. **Already asserted**: a full-object `equalTo(expected)` in the same test, or an existing integration test, already covers the fact. (Example: a single-field assert next to the full `equalTo(expectedRequest)`.)
5. **Scaffold**: the test only protects the act of making this change ("I might forget to wire this field"). It is done at GREEN. Remove it.

A retired, renamed, or added payload field is where items 1 and 3 fire most often. Put the effort into the working form (see "Keep" below).

TDD means: write no code that a test would have prevented. It does not mean a test at every step. Recommend no test when the honest answer is none. Say "verify manually" out loud, and do not offer a menu of cheaper options.

## Low-signal tests (propose removal)

- **Trivial mapping**: `from()` round-trip, getter/setter, field copy through layers, tested in isolation. A mapping test that checks two copied values belongs in the main mapper test, if anywhere.
- **Framework behaviour**: Hibernate writes a column, Jackson (de)serializes a record.
- **Framework configuration**: the test proves the global setup that every endpoint shares, not the feature. Examples: the shared `ObjectMapper` rejects unknown properties (`FAIL_ON_UNKNOWN_PROPERTIES`), the global exception handler maps `HttpMessageNotReadableException` to 400, default Bean Validation fires on `@Valid`. Signal: a fixture carries an unknown, retired, or non-existent field, and the test expects 400 / `MESSAGE_NOT_READABLE` / a parser error message. This test goes red only when someone edits the global config. It adds nothing to the new payload. Fix: delete the test and its fixture file.

Keep a rejection test when the code under change rejects the field itself, for example a custom validator or an explicit check for a retired field. That rejection is business logic of the feature.

## Keep: the working form

An integration test that drives the new feature through its real endpoint and database and asserts the feature's own data passes the gate. This includes save-then-fetch of a new form across its real branches (two applicants, optional sections absent, null optional values). It is the target for testing effort. It is not "X in, X out" plumbing: it proves the new mapping, persistence, and branching work together.

When you suggest a replacement for a removed test, prefer this kind of test: real Postgres (Testcontainers) + MockMvc over a new unit test.

## Example

Remove (tests global Jackson config, not the form):

```java
@Test
void shouldRejectFormCarryingAnUnknownField() throws Exception {
  // given
  var formPayload = TestUtil.readStringFromFile(UNKNOWN_FIELD_PAYLOAD_PATH);

  // then
  mockMvc
      .perform(post(SAVE_FORM_PATH)
          .contentType(MediaType.APPLICATION_JSON_VALUE)
          .content(formPayload))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.errorCode", is(ErrorCode.MESSAGE_NOT_READABLE.getCode())))
      .andExpect(jsonPath("$.errorMessage", containsString(RETIRED_FIELD)));
}
```

Keep (the working form, both insured persons, real branches):

```java
@Test
void shouldReturnSavedFormForBothApplicants() throws Exception {
  // given
  var formPayload = TestUtil.readStringFromFile(TWO_APPLICANTS_PAYLOAD_PATH);
  saveForm(formPayload);

  // when
  var savedForm = fetchSavedForm(formPayload);

  // then
  savedForm
      .andExpect(status().isOk())
      .andExpect(jsonPath(buildApplicantPath(FIRST_APPLICANT) + ".occupation", is("WORKER")))
      .andExpect(jsonPath(buildApplicantPath(SECOND_APPLICANT) + ".employmentEndDate").value(nullValue()))
      .andExpect(jsonPath(buildAddressPath(SECOND_APPLICANT) + ".secondaryAddress").value(nullValue()));
      // ... plus the remaining per-applicant assertions
}
```

## Missing coverage

Flag missing tests only where the change adds business logic to protect. Pure mapping edits, nullable column adds, record fields that pass through unchanged, and getter/setter additions need no new test. Manual verification is the accepted default for those.
