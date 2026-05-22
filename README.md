# EXE201App — YumeGo-ji (monorepo)

Repo gồm **API backend** (.NET 8) và **app mobile** (Flutter), dùng chung hệ thống EXE201.

```
EXE201App/
├── backend/     # ASP.NET Core API — http://localhost:5056
├── mobile/      # Flutter app
└── README.md
```

## 1. Backend

### Cấu hình lần đầu

```powershell
cd backend
copy appsettings.Example.json appsettings.json
copy appsettings.Example.json appsettings.Development.json
# Sửa ConnectionStrings (SQL Server) trong hai file vừa tạo
dotnet restore
dotnet run
```

API mặc định: **http://localhost:5056** (profile `http` trong `Properties/launchSettings.json`).

Database: chạy script trong `backend/doc/sql/` (DDL rồi seed).

### SQL Server (gợi ý)

- Server: `localhost`
- Database: `YumegojiDB`
- User/password: theo máy bạn (không commit mật khẩu thật lên Git).

## 2. Mobile (Flutter)

```powershell
cd mobile
flutter pub get
flutter run
```

| Thiết bị | API mặc định |
|----------|----------------|
| Android Emulator | `http://10.0.2.2:5056` |
| Máy thật (cùng Wi‑Fi) | `flutter run --dart-define=API_BASE_URL=http://<IP-PC>:5056` |

Đăng nhập Google (tùy chọn):

```powershell
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
```

## 3. Thứ tự chạy khi dev

1. Bật SQL Server + import DB (nếu chưa có).
2. `cd backend` → `dotnet run`.
3. `cd mobile` → `flutter run`.

## 4. So với EXE201 Web

- **Web**: frontend + backend (repo khác).
- **Repo này**: backend API + **client Flutter** — API tương thích Web (cùng cổng 5056).
