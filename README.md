# BigNumber

[![NuGet](https://img.shields.io/nuget/v/BigNumber?style=for-the-badge)](https://www.nuget.org/packages/BigNumber) [![License](https://img.shields.io/github/license/robertcoltheart/BigNumber?style=for-the-badge)](https://github.com/robertcoltheart/BigNumber/blob/master/LICENSE)

A collection of types for expressing very large numbers.

A port of [break_infinity.js](https://github.com/Patashu/break_infinity.js) and [break_eternity.js](https://github.com/Patashu/break_eternity.js).

## Usage
Install the package from NuGet with `dotnet add package BigNumber`.

Create numbers using one of the following:

```c#
var number = new BigNumber(12345);
```

```c#
var number = (BigNumber) 12345;
```

```c#
var number = BigNumber.Parse("1e308");
```

## Get in touch
Feel free to raise an [issue](https://github.com/robertcoltheart/BigNumber/issues).

## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## Acknowledgements
A port of the excellent [break_infinity.js](https://github.com/Patashu/break_infinity.js) and [break_eternity.js](https://github.com/Patashu/break_eternity.js).

## License
BigNumber is released under the [MIT License](LICENSE).
