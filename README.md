# Luau Brainfuck
Brainfuck interpreter written in Luau.

## Benchmarks
This interpreter was targeted at performance, a major optimization is merging continuous symbols into single instruction (example: ++++++ > +6).

Let's see it in action, here is a benchmark table for program which encodes "Hello, World!" with Caesar Cypher executed 1 million times in a row:
| Language | Duration (seconds) |
|-|-|
| Luau | 0.586119 |
| C | 0.034737 |
| Brainfuck (Luau) | 33.684436 |

As you can se- nevermind i'm abandoning this shit..
