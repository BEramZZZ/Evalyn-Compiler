# Evalyn Compiler — A Flex/Bison Expression Interpreter

A small interpreted expression language built from scratch in C, using **Flex** (lexical analysis) and **Bison** (syntax analysis / parsing). It started as a basic four-function calculator and has grown into a interpreter supporting variables, comparisons, statistical functions, and more — all evaluated live from an interactive command-line session.

```
> x = 5
x = 5
> y = 10
y = 10
> sqrt(x*x + y*y)
Result : 11.180340
> vars
x = 5
y = 10
```

---

## Table of contents

- [Features](#features)
- [Language reference](#language-reference)
- [How it works](#how-it-works)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Building](#building)
- [Usage](#usage)
- [Known limitations](#known-limitations)
- [Roadmap](#roadmap)
- [License](#license)

---

## Features

- **Full arithmetic**: `+ - * / % ^` with mathematically correct precedence and associativity
- **Unary minus** (`-5`), correctly disambiguated from binary subtraction
- **Parentheses** for explicit grouping
- **Math functions**: `sqrt`, `abs`
- **Statistical functions over argument lists**: `somme` (sum), `moyenne` (average), `variance`, `ecart_type` (standard deviation), `min`, `max`
- **Variables**: assignment, persistent storage across the session, and a `vars` command to list everything currently defined
- **Comparison operators**: `<`, `>`, `<=`, `>=`, `==`, `!=`, returning `1` (true) or `0` (false)
- **Smart output formatting**: whole-number results print as clean integers (`10`) instead of `10.000000`; genuine decimals still show full precision
- **Robust error handling**: division-by-zero detection, undefined-variable detection, and syntax-error recovery that lets the session continue instead of crashing after a bad line

---

## Language reference

### Literals

Numbers can be integers or decimals: `5`, `3.14`, `0.5`.

### Operators, from lowest to highest precedence

| Precedence  | Operators                   | Associativity      | Notes                                                       |
| ----------- | --------------------------- | ------------------ | ----------------------------------------------------------- |
| 1 (lowest)  | `<` `>` `<=` `>=` `==` `!=` | none (`%nonassoc`) | Cannot be chained — `1 < 2 < 3` is a syntax error by design |
| 2           | `+` `-`                     | left               |                                                             |
| 3           | `*` `/` `%`                 | left               | `%` is floating-point modulo (`fmod`)                       |
| 4           | unary `-`                   | none               | e.g. `-5`, `-x`                                             |
| 5 (highest) | `^`                         | right              | `2^3^2` = `2^(3^2)` = `512`                                 |

Comparisons intentionally sit at the _lowest_ precedence, so arithmetic on either side fully resolves before the comparison happens: `3 + 2 > 2 * 2` evaluates as `(3+2) > (2*2)` → `5 > 4` → `1`.

Comparison results are ordinary numbers (`1` or `0`), not a separate boolean type — the language has only one value type (float), so results can be printed, stored in variables, or used in further arithmetic just like any other number.

### Variables

```
x = 5
y = x * 2
```

- A variable name must start with a letter or underscore, followed by letters, digits, or underscores (`x`, `_temp`, `value2`).
- Assigning to an existing variable overwrites its value; assigning to a new name creates it.
- Variables persist for the lifetime of the running session (they're lost when the program exits).
- Reading an undefined variable prints an error and evaluates to `0` rather than crashing.

### The `vars` command

```
vars
```

Prints every variable currently defined, one per line, as `name = value`. Prints a message if no variables are defined yet.

### Built-in functions

| Function           | Syntax                     | Description                                        |
| ------------------ | -------------------------- | -------------------------------------------------- | --- | --- |
| Square root        | `sqrt(x)`                  | Square root of `x`                                 |
| Absolute value     | `abs(x)`                   | `                                                  | x   | `   |
| Sum                | `somme(a, b, c, ...)`      | Sum of all arguments                               |
| Average            | `moyenne(a, b, c, ...)`    | Arithmetic mean                                    |
| Variance           | `variance(a, b, c, ...)`   | Population variance                                |
| Standard deviation | `ecart_type(a, b, c, ...)` | Population standard deviation (`sqrt` of variance) |
| Minimum            | `min(a, b, c, ...)`        | Smallest argument                                  |
| Maximum            | `max(a, b, c, ...)`        | Largest argument                                   |

All statistical functions accept **any number of comma-separated arguments** (minimum one), and can take full sub-expressions as arguments, e.g. `somme(x, y*2, sqrt(16))`.

### Errors

| Situation              | Behavior                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| Division by zero       | Prints `Erreur: Division by zero`, result treated as `0`                                   |
| Undefined variable     | Prints `Erreur: variable '<name>' non definie`, value treated as `0`                       |
| Unrecognized character | Prints `Erreur lexicale: <char>`, character is skipped                                     |
| Invalid syntax         | Prints `Erreur: syntax error`, then recovers at the next newline and continues the session |

---

## How it works

This project follows the classic two-stage compiler/interpreter design:

```
  Raw text input
        │
        ▼
 ┌──────────────┐     tokens (NUM, '+', IDENT, ...)
 │  Lexer        │ ─────────────────────────────────►
 │  (LEXX.l →    │
 │   Flex)       │
 └──────────────┘
        │
        ▼ yylex() called repeatedly by the parser
 ┌──────────────┐
 │  Parser       │     matches grammar rules, runs
 │  (yacc.y →    │     semantic actions, evaluates
 │   Bison)      │     the expression as it parses
 └──────────────┘
        │
        ▼
   Printed result
```

**Lexical analysis** (`LEXX.l`) turns raw characters into tokens — it recognizes numbers, identifiers, keywords (`somme`, `sqrt`, `vars`, etc.), and operators, converting them into a stream Bison can work with. Whitespace is discarded; unrecognized characters are reported but don't halt execution.

**Syntax analysis** (`yacc.y`) defines the grammar — the valid ways tokens can combine into expressions — along with **semantic actions**: C code attached to each grammar rule that runs the moment that rule is matched. There's no separate "build a tree, then evaluate it" phase; evaluation happens _during_ parsing, which is why results print immediately as each line completes.

**Precedence and associativity** are declared explicitly (`%left`, `%right`, `%nonassoc`) so that ambiguous-looking expressions like `2 + 3 * 4` are always parsed the mathematically correct way, without needing the user to add parentheses everywhere.

**Variables** are stored in a simple in-memory symbol table (a fixed-size array of name/value pairs), looked up and updated as assignment and read operations occur.

**Error recovery** uses Bison's built-in `error` token: when the parser hits invalid input, it discards tokens until the next newline and resumes, rather than terminating the whole program over one bad line.

---

## Project structure

```
compiler-project/
├── src/
│   ├── LEXX.l      — lexer specification (Flex)
│   └── yacc.y      — grammar and evaluation logic (Bison)
├── .gitignore
├── README.md
└── LICENSE
```

Generated files (`lex.yy.c`, `yacc.tab.c`, `yacc.tab.h`) and the compiled binary are build artifacts, not source — they're excluded from version control and regenerated by the build steps below.

---

## Prerequisites

- **A C compiler** — `gcc` (via MinGW/MSYS2 on Windows, or natively on Linux/macOS)
- **Flex and Bison**
  - **Windows**: [WinFlexBison](https://github.com/lexxmark/winflexbison) (executables named `win_flex.exe` / `win_bison.exe`), or Flex/Bison via MSYS2/WSL
  - **Linux**: usually available via package manager, e.g. `sudo apt install flex bison`
  - **macOS**: available via Homebrew, e.g. `brew install flex bison`

---

## Building

### Windows (WinFlexBison)

From inside the project folder, in order:

```powershell
.\win_flex_bison-latest\win_bison.exe -d src\yacc.y
.\win_flex_bison-latest\win_flex.exe src\LEXX.l
gcc lex.yy.c yacc.tab.c -o final.exe -lm
```

### Linux / macOS

```bash
bison -d src/yacc.y
flex src/LEXX.l
gcc lex.yy.c yacc.tab.c -o final -lm
```

**Build order matters**: Bison must run first, since `LEXX.l` includes the header (`yacc.tab.h`) that Bison generates. Running Flex before Bison will fail at the compile step with a missing-header error.

---

## Usage

Run the compiled program and type expressions, one per line, ending each with Enter:

```
$ ./final
5+5
Result : 10
sqrt(16)
Result : 4
x = 7
x = 7
x >= 7
Result : 1
somme(2, 4, 6)
Result : 12
ecart_type(2, 4, 4, 4, 5, 5, 7, 9)
Result : 2
vars
x = 7
```

Exit by sending end-of-file (Ctrl+Z then Enter on Windows, Ctrl+D on Linux/macOS).

---

## Known limitations

- **No control flow** — no `if`/`else` or loops yet; every line is a single, independent statement or expression.
- **No user-defined functions** — only the built-in math/statistics functions listed above.
- **Fixed-size symbol table** — variables are capped at a maximum count (100 by default); exceeding this silently fails to store new variables.
- **Floating-point equality caveat** — `==`/`!=` compare floats directly, so results from computed (non-literal) values can occasionally be affected by standard floating-point precision limits.
- **No comments** — the language has no syntax for annotating code.
- **Single-session state** — variables are not saved between runs of the program.

---

## Roadmap

Planned or considered future additions:

- Conditional expressions (`if (cond) then (a) else (b)`)
- Full control flow with blocks and loops (`if`/`else`, `while`)
- User-defined functions
- Comments

---

## Author

BELAIDI Ramzy Zakaria — Master's student, USTHB (AI / Bioinformatics / CS)
