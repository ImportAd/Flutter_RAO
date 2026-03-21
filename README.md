# Document Generator — Flutter Web Frontend

Веб-интерфейс для генерации документов. Замена Telegram-бота.

## Требования

- Flutter SDK 3.2+ (с поддержкой Web)
- Запущенный бэкенд на `http://localhost:8000`

## Быстрый старт

```bash
# 1. Установить зависимости
flutter pub get

# 2. Запустить в режиме разработки
flutter run -d chrome --web-port 8080

# 3. Или собрать для деплоя
flutter build web --release
```

Билд появится в `build/web/` — его можно раздавать через FastAPI StaticFiles.

## Структура проекта

```
lib/
├── main.dart                           # Точка входа
├── app/
│   ├── app.dart                        # MaterialApp + GoRouter
│   └── theme.dart                      # Тема (бежево-золотая палитра РАО)
│
├── core/
│   ├── api/
│   │   └── api_client.dart             # Dio HTTP клиент
│   ├── models/
│   │   └── template_models.dart        # Модели данных (из API)
│   └── widgets/
│       ├── app_text_field.dart          # Текстовое поле (UI-kit)
│       └── app_buttons.dart            # Кнопки (UI-kit)
│
├── features/
│   ├── home/view/
│   │   └── home_page.dart              # Главная: выбор компании/формы/типа
│   ├── fill/
│   │   ├── view/
│   │   │   └── fill_page.dart          # Форма заполнения (compact/tabbed)
│   │   └── widgets/
│   │       ├── section_form.dart       # Динамическая форма секции
│   │       ├── table_form.dart         # Таблица с динамич. строками
│   │       └── review_panel.dart       # Проверка данных перед генерацией
│   └── success/view/
│       └── success_page.dart           # Экран успеха
│
└── shared/widgets/
    └── app_shell.dart                  # Общая обёртка страницы
```

## Два режима формы

Форма заполнения автоматически выбирает режим на основе шаблона:

- **Компактный** (АКТ, СОР) — все поля на одной странице, прокрутка
- **Многостраничный** (ЛД) — табы: Содержание → Таблица → Данные → Проверка

## Дизайн

Стилистика вдохновлена сайтом РАО:
- Бежево-золотая палитра
- Шрифты: Cormorant Garamond (заголовки) + Noto Sans (контент)
- Минималистичные формы с чёткой типографикой

## Деплой совместно с бэкендом

```python
# В backend/app/main.py — после сборки Flutter Web:
app.mount("/", StaticFiles(directory="../frontend/build/web", html=True))
```

Весь стек на одном порте (:8000):
- `/api/v1/*` — API бэкенда
- `/*` — Flutter Web SPA
