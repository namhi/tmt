## tmt


---

## Getting Started 🚀

If the CLI application is available on [pub](https://pub.dev), activate globally via:

```sh
dart pub global activate tmt
```

Or locally via:

```sh
dart pub global activate --source=path <path to this package>
```

or git via:
```sh
dart pub global activate  --source git https://github.com/namhi/tmt.git --git-ref=master

```
## Usage

```sh
# Sample command
$ tmt create bloc

# Sample command option
$ tmt create bloc my_bloc

# Command create bloc template with --force flag and dependencies

$ tmt create bloc customers --dependencies=customer_repository,receiver_repository,log_service --force

# Show CLI version
$ tmt --version

# Show usage help
$ tmt --help
```

## Running Tests with coverage 🧪

To run all unit tests use the following command:

```sh
$ dart pub global activate coverage 1.2.0
$ dart test --coverage=coverage
$ dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov)
.

```sh
# Generate Coverage Report
$ genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
$ open coverage/index.html
```

---

[coverage_badge]: coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli
