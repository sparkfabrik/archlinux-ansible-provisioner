# The system schema Schema

```txt
#/properties/system#/properties/system
```

An explanation about the purpose of this instance.

| Abstract            | Extensible | Status         | Identifiable | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                                |
| :------------------ | :--------- | :------------- | :----------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | No           | Forbidden         | Allowed               | none                | [configuration.schema.json*](../schemas/configuration.schema.json "open original schema") |

## system Type

`object` ([The system schema](configuration-properties-the-system-schema.md))

## system Default Value

The default value is:

```json
{}
```

## system Examples

```yaml
hostname: foobar
username: foobar
kernel: standard
timezone: Europe/Rome

```

# system Properties

| Property              | Type     | Required | Nullable       | Defined by                                                                                                                                                                       |
| :-------------------- | :------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [hostname](#hostname) | `string` | Required | cannot be null | [The root schema](configuration-properties-the-system-schema-properties-the-hostname-schema.md "#/properties/system/properties/hostname#/properties/system/properties/hostname") |
| [username](#username) | `string` | Required | cannot be null | [The root schema](configuration-properties-the-system-schema-properties-the-username-schema.md "#/properties/system/properties/username#/properties/system/properties/username") |
| [kernel](#kernel)     | `string` | Optional | cannot be null | [The root schema](configuration-properties-the-system-schema-properties-the-kernel-schema.md "#/properties/system/properties/kernel#/properties/system/properties/kernel")       |
| [timezone](#timezone) | `string` | Optional | cannot be null | [The root schema](configuration-properties-the-system-schema-properties-the-timezone-schema.md "#/properties/system/properties/timezone#/properties/system/properties/timezone") |
| Additional Properties | Any      | Optional | can be null    |                                                                                                                                                                                  |

## hostname

An explanation about the purpose of this instance.

`hostname`

*   is required

*   Type: `string` ([The hostname schema](configuration-properties-the-system-schema-properties-the-hostname-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-system-schema-properties-the-hostname-schema.md "#/properties/system/properties/hostname#/properties/system/properties/hostname")

### hostname Type

`string` ([The hostname schema](configuration-properties-the-system-schema-properties-the-hostname-schema.md))

### hostname Examples

```yaml
foobar

```

## username

An explanation about the purpose of this instance.

`username`

*   is required

*   Type: `string` ([The username schema](configuration-properties-the-system-schema-properties-the-username-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-system-schema-properties-the-username-schema.md "#/properties/system/properties/username#/properties/system/properties/username")

### username Type

`string` ([The username schema](configuration-properties-the-system-schema-properties-the-username-schema.md))

### username Examples

```yaml
foobar

```

## kernel

An explanation about the purpose of this instance.

`kernel`

*   is optional

*   Type: `string` ([The kernel schema](configuration-properties-the-system-schema-properties-the-kernel-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-system-schema-properties-the-kernel-schema.md "#/properties/system/properties/kernel#/properties/system/properties/kernel")

### kernel Type

`string` ([The kernel schema](configuration-properties-the-system-schema-properties-the-kernel-schema.md))

### kernel Examples

```yaml
standard

```

## timezone

An explanation about the purpose of this instance.

`timezone`

*   is optional

*   Type: `string` ([The timezone schema](configuration-properties-the-system-schema-properties-the-timezone-schema.md))

*   cannot be null

*   defined in: [The root schema](configuration-properties-the-system-schema-properties-the-timezone-schema.md "#/properties/system/properties/timezone#/properties/system/properties/timezone")

### timezone Type

`string` ([The timezone schema](configuration-properties-the-system-schema-properties-the-timezone-schema.md))

### timezone Examples

```yaml
Europe/Rome

```

## Additional Properties

Additional properties are allowed and do not have to follow a specific schema
