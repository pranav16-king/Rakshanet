# PROJECT AGENT INSTRUCTIONS

## 1. Core Rule
This project must use real, production-oriented implementation only.

Never add:
- Hardcoded business data
- Fake users
- Demo accounts
- Mock API responses
- Dummy database records
- Sample production records
- Placeholder statistics
- Fake GPS coordinates
- Fake locations
- Fake prices
- Fake measurements
- Fake authentication results
- Hardcoded tokens, API keys, passwords, secrets, or credentials
- Static lists that should come from the backend/database
- Artificial success/failure responses

If required data does not exist yet, implement the proper data flow and clearly identify the missing dependency instead of inventing data.

---

## 2. No Hardcoded Data
Never do this:
```dart
final users = [
  {"name": "John", "id": 1},
  {"name": "Demo User", "id": 2},
];
```
or:
```python
return {
    "status": "success",
    "users": 10
}
```
or:
```dart
final latitude = 19.8762;
final longitude = 75.3433;
```

Instead:
$$\text{UI} \longrightarrow \text{API} \longrightarrow \text{Service} \longrightarrow \text{Backend} \longrightarrow \text{Database} \longrightarrow \text{Real Response} \longrightarrow \text{UI}$$

Every dynamic value must have a legitimate source.

---

## 3. Data Source Rules
Before implementing any feature, determine where its data should come from.

**Priority:**
1. Existing backend API
2. Existing database
3. Existing authenticated user/session
4. Device APIs/sensors
5. External APIs configured through environment variables
6. User input
7. Computed data derived from real data

Do not create a fake source simply because the real source is not yet available.  
If the required backend/API/database functionality does not exist:
- Identify the missing API/schema/service.
- Implement the required architecture if appropriate.
- Do not return fake data.
- Do not silently substitute demo data.

---

## 4. Environment Variables
All environment-specific values must come from configuration.

Never hardcode:
- API keys
- JWT secrets
- Database URLs
- Cloudinary credentials
- Firebase credentials
- Third-party API keys
- OAuth secrets
- Passwords
- Encryption keys
- Service URLs when environment-dependent

Use appropriate configuration mechanisms such as:
- `.env`
- `.env.example`
- Environment configuration
- Secret manager
- CI/CD secrets

`.env.example` may contain variable names and safe placeholders, but never real credentials.  
Example:
```env
DATABASE_URL=
API_BASE_URL=
JWT_SECRET=
EXTERNAL_API_KEY=
```
Never commit actual secrets.

---

## 5. Backend Rules
For FastAPI/backend development:
- Use real database models.
- Use real database queries.
- Use proper validation with Pydantic.
- Use authentication and authorization.
- Use proper HTTP status codes.
- Handle database errors correctly.
- Do not return fake successful responses.
- Do not create endpoints that only simulate functionality.
- Do not bypass database persistence.
- Do not silently swallow exceptions.
- Do not expose secrets or internal errors to clients.
- If an endpoint requires data that is unavailable, return an appropriate error or empty state according to the API contract.

---

## 6. Database Rules
The database is the source of truth for persistent application data.

Do not maintain duplicate fake data inside:
- Dart files
- React files
- Python files
- JSON files
- Constants
- Services
- Controllers
- Providers
- Widgets

Use proper:
- Models
- Schemas
- Foreign keys
- Constraints
- Indexes
- Migrations
- Transactions
- Relationships

Never modify the database structure manually without considering migrations.  
For PostgreSQL:
$$\text{Application} \longrightarrow \text{FastAPI} \longrightarrow \text{SQLAlchemy / SQLModel} \longrightarrow \text{PostgreSQL}$$

Do not bypass this architecture unless the project explicitly requires it.

---

## 7. Frontend Rules
Frontend code must consume real application state.  
Do not use fake data to make a screen appear complete.  
Avoid:
- `Text("₹25,000")`
- `Text("1,248 Users")`
- `Text("Delhi")`
- `Text("98%")`
when these values are supposed to be dynamic.

Instead:
$$\text{Provider / State} \longrightarrow \text{Repository} \longrightarrow \text{API} \longrightarrow \text{Backend} \longrightarrow \text{Database}$$

The UI must support proper states:
- Loading
- Success
- Empty
- Error
- Unauthorized
- Offline
- Retry

An empty state is preferable to fake content.

---

## 8. API Integration
Before creating a new API:
- Check whether an existing API already provides the required data.
- Reuse existing services/repositories where appropriate.
- Follow existing API conventions.
- Verify request and response schemas.
- Handle authentication correctly.
- Handle errors.
- Avoid duplicate endpoints.
- Do not create an API that simply returns static JSON.

---

## 9. Authentication
Never hardcode:
- User ID
- Email
- Password
- JWT
- Access Token
- Refresh Token
- Role
- Permissions

Authentication information must come from the actual authentication system.  
Authorization must be validated on the backend.  
Never trust a frontend-provided role or permission without backend verification.

---

## 10. Location / GPS
Never hardcode geographic coordinates.  
Bad: `19.8762, 75.3433`

Use:
- Device GPS
- User-selected location
- Backend-provided location
- External mapping/geolocation service

If location permission is denied:
- Show a proper permission/error state.
- Do not substitute a random location.

---

## 11. External Services
For external services such as:
- Maps
- Payment gateways
- Cloud storage
- AI APIs
- Email
- SMS
- Wearables
- Weather
- Geolocation
- Analytics
- Authentication

use the configured integration.  
Never simulate successful external operations. For example, never show *"Payment Successful"* unless the actual payment flow confirms success.

---

## 12. AI / ML Features
AI-generated output must be based on actual input/context.  
Do not create fake AI responses such as:
*"Based on your health data, you are doing excellent."*  
unless the required real data exists.

AI services must receive:
$$\text{Real User Input} + \text{Real Application Context} + \text{Real Data}$$

If required data is unavailable, clearly represent the missing data.  
Never fabricate model results.

---

## 13. Error Handling
Never hide implementation problems by returning fake values.  
Bad:
```python
try:
    ...
except Exception:
    return {"success": True}
```

Correct approach:
$$\text{Log the real error} \longrightarrow \text{Handle it appropriately} \longrightarrow \text{Return meaningful error} \longrightarrow \text{Frontend shows error state}$$

Errors should be actionable and traceable.

---

## 14. Loading / Empty States
A missing dataset must not be replaced with demo content.  
Use:
- **Loading:** skeleton/loading UI
- **No data:** empty state
- **Error:** error state + retry
- **Unauthorized:** authentication state
- **Offline:** offline state

Example: `"No records available yet."` is valid.  
Creating: `"John completed 24 workouts"` just to populate the screen is **not valid**.

---

## 15. Existing Code First
Before modifying code:
- Inspect the existing architecture.
- Search for existing implementations.
- Identify reusable services/components.
- Check routing.
- Check state management.
- Check API contracts.
- Check database models.
- Check configuration.
- Follow existing project conventions.

Do not create duplicate services, repositories, models, API clients, routes, providers, controllers, components, or utilities unless there is a clear architectural reason.

---

## 16. Do Not Guess
If something is unknown:
- Do not assume.
- Do not invent.
- Do not fabricate.
- Do not silently choose arbitrary values.

Instead:
$$\text{Inspect code} \longrightarrow \text{Inspect config} \longrightarrow \text{Inspect DB/API} \longrightarrow \text{Search project files} \longrightarrow \text{Determine correct implementation}$$

If the required information genuinely does not exist, clearly state what is missing.

---

## 17. Production Quality
Every implementation should consider:
- Security
- Performance
- Scalability
- Error handling
- Validation
- Accessibility
- Maintainability
- Logging
- Testing
- Database integrity
- API consistency
- Authentication
- Authorization
- Offline/network behavior where relevant

Do not optimize only for making the UI look complete.

---

## 18. No Temporary Implementations
Do not leave code such as:
- `// TODO: replace with real API`
- `// FIXME: temporary fake data`
- `mock response`
- `demo response`
- `temporary user`
- `temporary coordinates`
- `temporary token`

unless the task explicitly requires a mock/test implementation.  
If a temporary implementation is absolutely necessary for testing, isolate it inside a clearly named test/mock environment and never connect it to production flows.

---

## 19. Testing
Tests may use controlled fixtures, mocks, and fake data when appropriate.  
However:
- Test data must remain inside test infrastructure.
- Test fixtures must not leak into production.
- Production services must never depend on test fixtures.
- Never use test credentials in production configuration.
- Testing exceptions do not permit demo data in the actual application.

---

## 20. UI/UX
UI should represent the actual state of the application.  
Design for:
- Real Data
- Loading
- Empty
- Error
- Success
- Offline
- Permission Denied
- Authentication Required

Do not populate screens with fake statistics simply to improve visual appearance.  
A visually empty screen with a correct empty state is better than a visually complete screen containing fabricated information.

---

## 21. Code Changes
When implementing a feature:
$$\text{Understand} \longrightarrow \text{Inspect} \longrightarrow \text{Design} \longrightarrow \text{Implement} \longrightarrow \text{Integrate} \longrightarrow \text{Validate} \longrightarrow \text{Test}$$

- Do not make unrelated changes.
- Do not rewrite working modules unnecessarily.
- Do not introduce new dependencies unless required.
- Do not duplicate existing functionality.

---

## 22. Dependency Rules
Before adding a package/library:
- Check whether the project already has an equivalent dependency.
- Check the existing architecture.
- Prefer established project dependencies.
- Add a new dependency only when justified.
- Do not add unnecessary packages.

---

## 23. Security Rules
Never expose:
- API keys
- Passwords
- JWT secrets
- Database credentials
- Private tokens
- Encryption keys
- Internal service credentials

Never commit secrets.  
Never log sensitive credentials.  
Never return sensitive database fields unless required.  
Validate all user-controlled input.  
Use parameterized queries / ORM mechanisms.

---

## 24. Final Verification
Before considering a task complete, verify:
- **Data:** No hardcoded production data, no fake records, no demo users, no fake API responses, no fake coordinates, no fake metrics.
- **Backend:** API works with real data, database operations are real, validation exists, errors are handled, authentication/authorization are respected.
- **Frontend:** Real API integration, correct loading state, correct empty state, correct error state, no fabricated values.
- **Security:** No secrets committed, no credentials hardcoded, no sensitive information exposed.
- **Architecture:** Existing patterns reused, no unnecessary duplication, no broken dependencies, no unrelated modifications.

---

## 25. Absolute Rule
**NEVER fabricate data to make the application look functional.**  
If real data is unavailable:
- Show the correct empty/loading/error state or implement the missing data source.
- Do not invent data.

The application must reflect what actually exists, not what would make the demo look better.
