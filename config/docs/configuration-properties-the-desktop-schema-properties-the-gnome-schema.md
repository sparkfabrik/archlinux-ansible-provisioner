# The gnome schema Schema

```txt
#/properties/desktop/properties/gnome#/properties/desktop/properties/gnome
```

An explanation about the purpose of this instance.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                                |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [configuration.schema.json*](../schemas/configuration.schema.json "open original schema") |

## gnome Type

`object` ([The gnome schema](configuration-properties-the-desktop-schema-properties-the-gnome-schema.md))

## gnome Default Value

The default value is:

```json
{}
```

## gnome Examples

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

# gnome Properties

| Property                  | Type    | Required | Nullable       | Defined by                                                                                                                                                                                                                                              |
| :------------------------ | :------ | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [extensions](#extensions) | `array` | Required | cannot be null | [The root schema](configuration-properties-the-desktop-schema-properties-the-gnome-schema-properties-the-extensions-schema.md "#/properties/desktop/properties/gnome/properties/extensions#/properties/desktop/properties/gnome/properties/extensions") |
| Additional Properties     | Any     | Optional | can be null    |                                                                                                                                                                                                                                                         |

## extensions

An explanation about the purpose of this instance.

`extensions`

*   is required

*   Type: an array of merged types ([Details](configuration-properties-the-desktop-schema-properties-the-gnome-schema-properties-the-extensions-schema-items.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-desktop-schema-properties-the-gnome-schema-properties-the-extensions-schema.md "#/properties/desktop/properties/gnome/properties/extensions#/properties/desktop/properties/gnome/properties/extensions")

### extensions Type

an array of merged types ([Details](configuration-properties-the-desktop-schema-properties-the-gnome-schema-properties-the-extensions-schema-items.md))

### extensions Default Value

The default value is:

```json
[]
```

### extensions Examples

```yaml
- appindicatorsupport@rgcjonas.gmail.com
- just-perfection-desktop@just-perfection

```

## Additional Properties

Additional properties are allowed and do not have to follow a specific schema
