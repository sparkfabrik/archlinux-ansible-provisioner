# The desktop schema Schema

```txt
#/properties/desktop#/properties/desktop
```

An explanation about the purpose of this instance.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                                |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [configuration.schema.json*](../schemas/configuration.schema.json "open original schema") |

## desktop Type

`object` ([The desktop schema](configuration-properties-the-desktop-schema.md))

## desktop Default Value

The default value is:

```json
{}
```

## desktop Examples

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

# desktop Properties

| Property                      | Type      | Required | Nullable       | Defined by                                                                                                                                                                                      |
| :---------------------------- | :-------- | :------- | :------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [gnome](#gnome)               | `object`  | Required | cannot be null | [The root schema](configuration-properties-the-desktop-schema-properties-the-gnome-schema.md "#/properties/desktop/properties/gnome#/properties/desktop/properties/gnome")                      |
| [x11_gestures](#x11_gestures) | `boolean` | Optional | cannot be null | [The root schema](configuration-properties-the-desktop-schema-properties-the-x11_gestures-schema.md "#/properties/desktop/properties/x11_gestures#/properties/desktop/properties/x11_gestures") |
| [office](#office)             | `boolean` | Optional | cannot be null | [The root schema](configuration-properties-the-desktop-schema-properties-the-office-schema.md "#/properties/desktop/properties/office#/properties/desktop/properties/office")                   |
| Additional Properties         | Any       | Optional | can be null    |                                                                                                                                                                                                 |

## gnome

An explanation about the purpose of this instance.

`gnome`

*   is required

*   Type: `object` ([The gnome schema](configuration-properties-the-desktop-schema-properties-the-gnome-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-desktop-schema-properties-the-gnome-schema.md "#/properties/desktop/properties/gnome#/properties/desktop/properties/gnome")

### gnome Type

`object` ([The gnome schema](configuration-properties-the-desktop-schema-properties-the-gnome-schema.md))

### gnome Default Value

The default value is:

```json
{}
```

### gnome Examples

```yaml
extensions:
  - appindicatorsupport@rgcjonas.gmail.com
  - just-perfection-desktop@just-perfection
  - screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com
  - user-theme@gnome-shell-extensions.gcampax.github.com
  - workspace-indicator@gnome-shell-extensions.gcampax.github.com']
  - dash-to-dock@micxgx.gmail.com
  - ding@rastersoft.com

```

## x11\_gestures

An explanation about the purpose of this instance.

`x11_gestures`

*   is optional

*   Type: `boolean` ([The x11\_gestures schema](configuration-properties-the-desktop-schema-properties-the-x11\_gestures-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-desktop-schema-properties-the-x11\_gestures-schema.md "#/properties/desktop/properties/x11\_gestures#/properties/desktop/properties/x11\_gestures")

### x11\_gestures Type

`boolean` ([The x11\_gestures schema](configuration-properties-the-desktop-schema-properties-the-x11\_gestures-schema.md))

### x11\_gestures Examples

```yaml
true

```

## office

An explanation about the purpose of this instance.

`office`

*   is optional

*   Type: `boolean` ([The office schema](configuration-properties-the-desktop-schema-properties-the-office-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-desktop-schema-properties-the-office-schema.md "#/properties/desktop/properties/office#/properties/desktop/properties/office")

### office Type

`boolean` ([The office schema](configuration-properties-the-desktop-schema-properties-the-office-schema.md))

### office Examples

```yaml
false

```

## Additional Properties

Additional properties are allowed and do not have to follow a specific schema
