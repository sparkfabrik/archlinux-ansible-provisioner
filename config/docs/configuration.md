# The root schema Schema

```txt
http://example.com/example.json
```

The root schema comprises the entire JSON document.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                               |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :--------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [configuration.schema.json](../schemas/configuration.schema.json "open original schema") |

## The root schema Type

`object` ([The root schema](configuration.md))

## The root schema Default Value

The default value is:

```json
{}
```

## The root schema Examples

```yaml
system:
  hostname: foobar
  username: foobar
  kernel: standard
desktop:
  gnome:
    extensions:
      - appindicatorsupport@rgcjonas.gmail.com
      - just-perfection-desktop@just-perfection
      - screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com
      - user-theme@gnome-shell-extensions.gcampax.github.com
      - workspace-indicator@gnome-shell-extensions.gcampax.github.com']
      - dash-to-dock@micxgx.gmail.com
      - ding@rastersoft.com
  x11_gestures: true
  office: false
debug: false

```

# The root schema Properties

| Property              | Type      | Required | Nullable       | Defined by                                                                                                   |
| :-------------------- | :-------- | :------- | :------------- | :----------------------------------------------------------------------------------------------------------- |
| [system](#system)     | `object`  | Required | cannot be null | [The root schema](configuration-properties-the-system-schema.md "#/properties/system#/properties/system")    |
| [desktop](#desktop)   | `object`  | Required | cannot be null | [The root schema](configuration-properties-the-desktop-schema.md "#/properties/desktop#/properties/desktop") |
| [debug](#debug)       | `boolean` | Required | cannot be null | [The root schema](configuration-properties-the-debug-schema.md "#/properties/debug#/properties/debug")       |
| Additional Properties | Any       | Optional | can be null    |                                                                                                              |

## system

An explanation about the purpose of this instance.

`system`

*   is required

*   Type: `object` ([The system schema](configuration-properties-the-system-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-system-schema.md "#/properties/system#/properties/system")

### system Type

`object` ([The system schema](configuration-properties-the-system-schema.md))

### system Default Value

The default value is:

```json
{}
```

### system Examples

```yaml
hostname: foobar
username: foobar
kernel: standard
timezone: Europe/Rome

```

## desktop

An explanation about the purpose of this instance.

`desktop`

*   is required

*   Type: `object` ([The desktop schema](configuration-properties-the-desktop-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-desktop-schema.md "#/properties/desktop#/properties/desktop")

### desktop Type

`object` ([The desktop schema](configuration-properties-the-desktop-schema.md))

### desktop Default Value

The default value is:

```json
{}
```

### desktop Examples

```yaml
gnome:
  extensions:
    - appindicatorsupport@rgcjonas.gmail.com
    - just-perfection-desktop@just-perfection
    - screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com
    - user-theme@gnome-shell-extensions.gcampax.github.com
    - workspace-indicator@gnome-shell-extensions.gcampax.github.com']
    - dash-to-dock@micxgx.gmail.com
    - ding@rastersoft.com
x11_gestures: true
office: false

```

## debug

An explanation about the purpose of this instance.

`debug`

*   is required

*   Type: `boolean` ([The debug schema](configuration-properties-the-debug-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-debug-schema.md "#/properties/debug#/properties/debug")

### debug Type

`boolean` ([The debug schema](configuration-properties-the-debug-schema.md))

### debug Examples

```yaml
false

```

## Additional Properties

Additional properties are allowed and do not have to follow a specific schema
