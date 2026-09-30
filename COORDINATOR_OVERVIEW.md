# Как устроена навигация в RickVerse

> Справочник по навигационному слою: Coordinator + `NavigationStack` + deep links.
> Файл-напоминалка — чтобы вернуться и быстро восстановить картину.

## Главная идея в одном предложении

**Навигация — это не действия, а состояние.** Никто нигде не «пушит экран». Кто-то меняет переменную, а SwiftUI сам перерисовывает стек так, чтобы он соответствовал новому значению. Отсюда всё остальное.

---

## Слой 1. Дерево владения: кто кем владеет

```
rick_verseApp                        (@main)
└── AppShellView                     @State private var coordinator = AppCoordinator()  ← корень
    ├── SplashView                   (phase == .splash)
    └── TabBarView                   (phase == .tabs)
        ├── CharactersTab  ← coordinator.characters   (CharactersCoordinator)
        ├── EpisodesTab    ← coordinator.episodes     (EpisodesCoordinator)
        ├── LocationsTab   ← coordinator.locations    (LocationsCoordinator)
        ├── FavoritesTab   ← coordinator.favorites    (FavoritesCoordinator)
        └── SettingsTab    ← coordinator.settings     (SettingsCoordinator)
```

Ключевой момент: **`AppCoordinator` создаётся один раз** в `AppShellView.swift:12` как `@State`, и он владеет всеми пятью дочерними координаторами как `let`-свойствами (`AppCoordinator.swift:32-36`).

Почему это важно: дочерние координаторы живут столько же, сколько приложение. Поэтому когда вы ушли из таба Characters на 3 экрана вглубь, переключились на Episodes и вернулись — **вы вернётесь на те же 3 экрана вглубь**. Стек не сбросился, потому что объект, который его хранит, никуда не делся.

---

## Слой 2. Две фазы приложения

`AppCoordinator` держит `phase: Phase` (`.splash` / `.tabs`), а `AppShellView` — это просто `switch` по ней:

```swift
switch coordinator.phase {
case .splash: SplashView().task { await coordinator.runSplash() }
case .tabs:   TabBarView(coordinator: coordinator, container: container)
}
```

`runSplash()` спит 1.5 сек и ставит `phase = .tabs`. Всё. Никакого «перехода» — просто другая ветка `switch` начинает рендериться, а `.animation(.default, value: coordinator.phase)` делает это плавным.

---

## Слой 3. Две независимые «оси» навигации

Самая концептуально важная часть; подробно задокументирована в комментарии `CharactersCoordinator.swift:11-19`.

Внутри одного таба есть **две разные оси**, и они принципиально не смешиваются:

### Ось Push (стек)

```swift
enum Route: Hashable {
    case characterDetail(id: Int)
}
var path: [Route] = []
```

- Это **массив** — экранов может быть много, один поверх другого.
- `Route` — **`Hashable`**, потому что `NavigationStack` хеширует значения, чтобы отличать экраны друг от друга.

### Ось Present (модалка)

```swift
enum Sheet: Identifiable {
    case filters
    var id: String { ... }
}
var presentedSheet: Sheet?
```

- Это **Optional** — модалка либо одна, либо её нет. Стека тут быть не может.
- `Sheet` — **`Identifiable`**, потому что `.sheet(item:)` нужен только ответ «что показано, если вообще показано».

**Почему нельзя было объединить:** `NavigationStack` умеет только push/pop. Шторку в `path` не положишь физически. Поэтому — две разные переменные с разными протоколами. Третьей аналогичной осью был бы `fullScreenCover`.

---

## Слой 4. Как `path` превращается в экраны

`CharactersTab.swift` — здесь состояние встречается с UI:

```swift
NavigationStack(path: $coordinator.path) {          // ① биндинг на массив
    CharactersListView(...)                          // ② корень стека
        .navigationDestination(for: Route.self) { route in   // ③ рецепт
            switch route {
            case let .characterDetail(id):
                CharacterDetailView(
                    viewModel: container.makeCharacterDetailViewModel(id: id)
                )
            }
        }
}
.sheet(item: $coordinator.presentedSheet) { ... }    // ④ вторая ось, рядом
```

Читается так:

1. **`NavigationStack(path:)`** — «мой стек отражает вот этот массив».
2. Корневой экран — то, что видно при пустом `path`.
3. **`navigationDestination`** — это **не переход**, а *рецепт*: «если в массиве встретится значение `.characterDetail(id:)`, построй вот такой экран». Регистрируется один раз, вызывается по требованию.
4. Шторка висит на `NavigationStack` **снаружи** — параллельная ось.

### Что делает `$` перед `coordinator.path`

`@Bindable var coordinator` (`CharactersTab.swift:12`) даёт двустороннюю связь с `@Observable`-объектом. Это критично:

- **Вы → UI:** `path.append(...)` → экран появился.
- **UI → вы:** пользователь нажал «Назад» или свайпнул → **SwiftUI сам удалил элемент из `path`**.

Второе направление — то, почему нигде в коде нет обработки кнопки «назад». Она бесплатна.

---

## Слой 5. Полный путь одного тапа

Тап по карточке персонажа сверху донизу:

```
① CharactersListView.swift:148
   Button { onSelect(character.id) }
   └─ View знает только Int. Ни о каком CharacterDetailView не подозревает.

② CharactersTab.swift:19
   onSelect: { id in coordinator.showCharacterDetail(id: id) }
   └─ Замыкание — это шов. Здесь "что-то выбрали" переводится в "покажи детали".

③ CharactersCoordinator.swift:33
   func showCharacterDetail(id: Int) { path.append(.characterDetail(id: id)) }
   └─ Просто мутация массива. Единственное "решение о навигации" во всей цепочке.

④ @Observable замечает изменение path → SwiftUI перерисовывает NavigationStack

⑤ NavigationStack видит новый элемент, ищет рецепт в navigationDestination

⑥ container.makeCharacterDetailViewModel(id: 42)
   └─ AppContainer.swift:70 собирает VM из репозитория + use case

⑦ CharacterDetailView появляется с анимацией push
```

**Чего в цепочке нет:** ViewModel в ней не участвует вообще. `CharactersListViewModel` не знает о навигации ничего — он занят только загрузкой, поиском и пагинацией. Это правило из `context/project-overview.md`: *«ViewModels know nothing about navigation»*.

Именно поэтому VM-ки тестируются тривиальными моками — у них нет навигационных зависимостей, которые пришлось бы подделывать.

---

## Слой 6. Переключение табов

```swift
TabView(selection: $coordinator.selectedTab) {
    Tab(..., value: .characters) { CharactersTab(...) }
    ...
}
```

Тот же принцип: `selectedTab` — обычное свойство `AppCoordinator`. Тапнул пользователь — SwiftUI записал новое значение. Записали вы из кода — таб переключился. Симметрично.

`Tab(...) { }` — это **новый API iOS 18**, не старый `.tabItem`. Значения `title` и `systemImage` берутся из расширения `AppCoordinator.Tab` (`AppCoordinator.swift:93-115`), то есть подписи табов имеют один источник истины.

---

## Слой 7. Почему deep links «просто работают»

`AppCoordinator.apply(_:)` (`AppCoordinator.swift:81`):

```swift
case let .characterDetail(id):
    selectedTab = .characters                        // ① какой таб
    characters.path = [.characterDetail(id: id)]     // ② какой стек
```

Строка ② — **присваивание целого массива**, а не `append`. Это разница между «пушни экран» и «стек теперь выглядит вот так». Второе идемпотентно и не зависит от того, где пользователь был раньше: он мог быть на 4 экранах вглубь в табе Settings — неважно, состояние заменяется целиком.

Открыть экран на 3 уровня вглубь — это `path = [.a, .b, .c]`. Одна строка, без промежуточных анимаций и без гонок.

### Буфер на холодный старт

`pendingDeepLink` (`AppCoordinator.swift:44`) решает классический баг: ссылка приходит, пока на экране ещё splash, а табов физически не существует.

```swift
func handle(_ link: DeepLink) {
    guard phase == .tabs else { pendingDeepLink = link; return }   // отложить
    apply(link)
}
```

В конце `runSplash()` отложенная ссылка проигрывается. Без этого запись в `characters.path` ушла бы в никуда.

### Что уже собрано

| Элемент | Файл |
|---|---|
| URL-схема `rickverse://` | `Config/Info.plist:45-55` |
| Парсер URL → intent | `rick-verse/App/DeepLink.swift` |
| Точка входа `.onOpenURL` | `AppShellView.swift:43` |
| Трансляция intent → навигация | `AppCoordinator.apply(_:)` |
| Буферизация во время splash | `AppCoordinator.pendingDeepLink` |

Поддерживаются `rickverse://characters` и `rickverse://character/42`.

---

## Слой 8. Правило кросс-табовой навигации

В `AppCoordinator` есть комментарий: *«Cross-tab navigation … is the only place it is allowed»*.

Контраст хорошо виден на Favorites:

- **Favorites → Character Detail внутри своего таба** — это **не** кросс-таб. У `FavoritesCoordinator` свой `Route.characterDetail` и свой `path`. `AppCoordinator` не участвует (см. комментарий `FavoritesCoordinator.swift:9-10`).
- **Favorites → Character Detail в табе Characters** — вот это кросс-таб: надо тронуть и `selectedTab`, и чужой `path`. Такое разрешено только в `AppCoordinator`.

Логика правила: координатор таба не имеет права дотягиваться до чужого таба. Иначе они начинают знать друг о друге, и вместо дерева получается граф связей.

Побочный эффект: `CharacterDetailView` существует в двух стеках независимо. Открыв Рика из Favorites, вы не увидите его в стеке Characters — это два разных экрана. Для такого приложения это правильное поведение (каждый таб помнит своё), просто стоит понимать, что так задумано.

---

## Слой 9. Пустые координаторы — это заготовки

```swift
@Observable
final class EpisodesCoordinator {
    enum Route: Hashable {}    // ← ноль кейсов
    var path: [Route] = []
}
```

`enum Route: Hashable {}` без кейсов — тип, у которого **не может существовать ни одного значения**. Значит `path` гарантированно всегда пуст, а `navigationDestination` в `EpisodesTab` возвращает `EmptyView()`, потому что компилятору нужна хоть какая-то ветка, которая никогда не выполнится.

Это не «недоделка», а способ держать структуру одинаковой во всех табах. Когда появится Episode Detail — добавляете кейс в `Route`, и компилятор сам покажет все места, которые надо дописать.

Так сейчас у `EpisodesCoordinator`, `LocationsCoordinator`, `SettingsCoordinator`.

---

## Шпаргалка

| Хочу | Что менять |
|---|---|
| Пушнуть экран | `coordinator.path.append(.route)` |
| Вернуться назад | ничего — SwiftUI сам, или `path.removeLast()` |
| В корень таба | `path = []` |
| Открыть шторку | `presentedSheet = .filters` |
| Сменить таб | `appCoordinator.selectedTab = .episodes` |
| Deep link | `selectedTab = …` + `path = [...]` в `AppCoordinator.apply` |
| Новый экран в табе | кейс в `Route` → ветка в `navigationDestination` → метод в координаторе |

**Одна фраза на память:** координатор держит состояние, `NavigationStack` его отражает, View сообщает о намерении замыканием, ViewModel о навигации не знает.

---

## Карта файлов

| Файл | Роль |
|---|---|
| `rick-verse/App/AppCoordinator.swift` | Корневой координатор: phase, selectedTab, 5 дочерних, deep links |
| `rick-verse/App/AppShellView.swift` | Splash ↔ Tabs, `.onOpenURL`, установка environment |
| `rick-verse/App/TabBarView.swift` | `TabView` с пятью табами |
| `rick-verse/App/DeepLink.swift` | Парсер URL → intent (чистая функция) |
| `rick-verse/App/AppContainer.swift` | Composition root: фабрики ViewModel'ей |
| `Presentation/<Feature>/<Feature>Coordinator.swift` | `Route`, `path`, методы навигации флоу |
| `Presentation/<Feature>/<Feature>Tab.swift` | `NavigationStack` + `navigationDestination` |
| `Config/Info.plist` | `CFBundleURLTypes` — регистрация схемы `rickverse` |
