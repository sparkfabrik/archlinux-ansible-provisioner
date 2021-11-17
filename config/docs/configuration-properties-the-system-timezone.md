# The system timezone Schema

```txt
#/properties/timezone#/properties/timezone
```

The system timezone used in /etc/localtime

| Abstract            | Extensible | Status         | Identifiable            | Custom Properties | Additional Properties | Access Restrictions | Defined In                                                                                |
| :------------------ | :--------- | :------------- | :---------------------- | :---------------- | :-------------------- | :------------------ | :---------------------------------------------------------------------------------------- |
| Can be instantiated | No         | Unknown status | Unknown identifiability | Forbidden         | Allowed               | none                | [configuration.schema.json*](../schemas/configuration.schema.json "open original schema") |

## timezone Type

`string` ([The system timezone](configuration-properties-the-system-timezone.md))

## timezone Default Value

The default value is:

```json
"Europe/Rome"
```

## timezone Examples

```yaml
Europe/Rome

```

```yaml
Europe/Madrid

```
