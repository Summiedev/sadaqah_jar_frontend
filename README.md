# Sadaqah Jar Frontend

## Backend Host Configuration

The app reads backend host from compile-time environment key `API_BASE_URL`.

1. Copy `env/app_config.example.json` to `env/app_config.json`.
2. Set your backend URL in `env/app_config.json`.

Example:

```json
{
	"API_BASE_URL": "http://192.168.1.20:8000/api/v1"
}
```

## Run

```bash
flutter pub get
flutter run --dart-define-from-file=env/app_config.json
```

## Analyze And Test

```bash
flutter analyze
flutter test
```

## Security Notes

- Use `https://...` for production backend host.
- Never commit real production URLs or secrets into config files.
- Keep authentication tokens private and clear them on logout (already implemented).
