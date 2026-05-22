# Project Overview

Hython is a Python interpreter written in Haxe.

# Goals

- Fast startup
- Pythonic syntax
- Simple runtime architecture

# Architecture

- Lexer
- Parser
- AST
- Evaluator

# Runtime Rules

- Everything is a PyValue
- Closures are lexical
- Methods are late-bound

# Coding Style

- Prefer pattern matching
- Avoid Dynamic
- Use explicit enums

# Forbidden

- No macro magic
- No hidden global state

# Future Plans

- Async/Await
- modules