package langlang

//
//
//
// Alternative = Term { Term }
// Term = Identifier | Token { "..." Token } | Group | Option | Repetition
// Group = "(" Expression ")"				Może wystąpić jeden z elementów grupy np "+" lub "-"
// Option = "[" Expression "]"				Może wystąpić zero lub jedna expr
// Repetition = "{" Expression "}" 			Może wystąpić zero lub wiele expr
