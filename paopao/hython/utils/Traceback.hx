// This file renders errors in the CPython traceback style, including the
// source-snippet indicator introduced in CPython 3.11:
//
//   Traceback (most recent call last):
//     File "<python-input-0>", line 1, in <module>
//       10 * (1/0)
//             ~^~
//   ZeroDivisionError: division by zero
//
// Usage
//   // Minimal — source lines resolved automatically from `source`.
//   var tb = new Traceback(source);
//   tb.pushFrame(error.filename, error.line, "<module>", error.span);
//   throw tb.format(error);          // returns the full string
//
//   // Rich — multiple frames (innermost pushed last).
//   var tb = new Traceback(source);
//   tb.pushFrame("main.py", 12, "outer", null);
//   tb.pushFrame("main.py",  5, "inner", error.span);
//   trace(tb.format(error));
//
// The Traceback object is intentionally separate from Error so that the
// renderer can be used from any layer (compiler, semantic analyser, VM)
// without coupling source-text storage to the error data structure.
package paopao.hython.utils;

import paopao.hython.Error;

// TraceFrame — one entry in the "Traceback (most recent call last):" block.

typedef TraceFrame = {
	// File or input name shown in the "File …" header line.
	// Use "<module>" for top-level REPL input, or a real path like "main.py".
	var filename:String;

	// 1-based line number within the file.
	var line:Int;

	// Enclosing scope: "<module>", function name, "<lambda>", class name, …
	var scope:String;

	// Raw source line text (leading whitespace preserved for the indent display).
	// May be the empty string when source is unavailable.
	var sourceLine:String;

	// Optional column-level highlight (see Span in Error.hx).
	var span:Null<Span>;
}

class Traceback {
	// All source lines split on '\n' (index = line - 1).
	private var sourceLines:Array<String>;

	// Frames collected so far — outermost first, innermost last.
	private var frames:Array<TraceFrame>;

	// Construction

	// `source` is the full source text of the file being executed.
	// Pass an empty string when source is not available (snippet will be blank).
	public function new(source:String) {
		this.sourceLines = source.split("\n");
		this.frames = [];
	}

	// Frame Registration

	// Append one call-stack frame.  Call this for every level from outermost
	// to innermost before calling format().
	//
	// `line`  — 1-based line number (used to extract the source snippet).
	// `scope` — scope label shown after "in": e.g. "<module>", "my_function".
	// `span`  — optional column range for the indicator line; pass null when
	//           the full-line source snippet without indicator is sufficient.
	public function pushFrame(filename:String, line:Int, scope:String, span:Null<Span>):Void {
		var sourceLine = getSourceLine(line);
		frames.push({
			filename: filename,
			line: line,
			scope: scope,
			sourceLine: sourceLine,
			span: span
		});
	}

	// Convenience: push a single frame directly from an Error object.
	// The scope is taken as "<module>" unless overridden.
	public function pushFromError(error:Error, ?scope:String):Void {
		pushFrame(error.filename, error.line, scope != null ? scope : "<module>", error.span);
	}

	// Rendering

	// Build and return the full CPython-style traceback string.
	//
	// The returned string looks like:
	//
	//   Traceback (most recent call last):
	//     File "main.py", line 5, in outer
	//       call_inner()
	//       ^^^^^^^^^^^^
	//     File "main.py", line 2, in inner
	//       10 * (1/0)
	//             ~^~
	//   ZeroDivisionError: division by zero
	public function format(error:Error):String {
		var sb = new StringBuf();

		sb.add("Traceback (most recent call last):\n");

		for (frame in frames) {
			sb.add('  File "${frame.filename}", line ${frame.line}, in ${frame.scope}\n');

			if (frame.sourceLine.length > 0) {
				// Render the source line with 4-space indent.
				sb.add("    ");
				sb.add(frame.sourceLine);
				sb.add("\n");

				// Render the indicator only when span information is available.
				if (frame.span != null) {
					var indicator = buildIndicator(frame.sourceLine, frame.span);
					if (indicator.length > 0) {
						sb.add("    ");
						sb.add(indicator);
						sb.add("\n");
					}
				}
			}
		}

		// Final error line: "ErrorName: message"
		sb.add(error.errorName());
		sb.add(": ");
		sb.add(error.errorMessage());

		return sb.toString();
	}

	// One-shot helper for the common single-frame case (REPL, module-level error).
	//
	//   var msg = Traceback.simple(source, error);
	//   trace(msg);
	public static function simple(source:String, error:Error, ?scope:String):String {
		var tb = new Traceback(source);
		tb.pushFromError(error, scope);
		return tb.format(error);
	}

	// Indicator Building

	// Given a raw source line and a Span, produce the indicator string that
	// sits underneath the source line (without the leading 4-space indent —
	// that is added by the caller).
	//
	// Rules
	// -----
	//  • When span.opStart / span.opEnd are null:
	//      all columns in [colStart, colEnd] become `^`
	//
	//      undefined_var + 1
	//      ^^^^^^^^^^^^^
	//
	//  • When opStart / opEnd are set:
	//      [colStart, opStart)  → `~`   (left operand)
	//      [opStart,  opEnd]    → `^`   (operator)
	//      (opEnd,    colEnd]   → `~`   (right operand)
	//
	//      10 * (1/0)
	//            ~^~
	//
	//  • Leading spaces match the source line's own indentation so the
	//    indicator aligns correctly regardless of indent depth.
	//
	// All column values are 1-based and clamped to the actual line length.
	private function buildIndicator(sourceLine:String, span:Span):String {
		var len = sourceLine.length;
		if (len == 0) return "";

		// Clamp all values to valid range.
		var cs = clamp(span.colStart, 1, len);     // colStart  (1-based)
		var ce = clamp(span.colEnd,   cs, len);    // colEnd    (1-based, inclusive)

		// Convert to 0-based for string building.
		var start = cs - 1;
		var end   = ce - 1; // inclusive

		var sb = new StringBuf();

		// Prefix: spaces that match the source line's leading whitespace,
		// then additional spaces up to the start of the highlighted region.
		// We reproduce the exact leading character (space or tab) so the
		// indicator stays aligned even with mixed indentation.
		for (i in 0...start) {
			var ch = sourceLine.charAt(i);
			sb.add(ch == "\t" ? "\t" : " ");
		}

		if (span.opStart == null || span.opEnd == null) {
			// All-caret style
			for (_ in start...(end + 1))
				sb.add("^");
		} else {
			// Binary-op tilde-caret style
			var os = clamp(span.opStart, cs, ce) - 1; // 0-based
			var oe = clamp(span.opEnd,   cs, ce) - 1; // 0-based (inclusive)

			// Left operand: ~ from [start, os)
			for (_ in start...os)
				sb.add("~");

			// Operator: ^ from [os, oe]
			for (_ in os...(oe + 1))
				sb.add("^");

			// Right operand: ~ from (oe, end]
			for (_ in (oe + 1)...(end + 1))
				sb.add("~");
		}

		return sb.toString();
	}

	// Utilities

	// Return the 1-based `line` from the source, or "" if out of range.
	private function getSourceLine(line:Int):String {
		var idx = line - 1;
		if (idx < 0 || idx >= sourceLines.length) return "";
		// Strip trailing \r from CRLF files.
		var raw = sourceLines[idx];
		if (raw.length > 0 && raw.charAt(raw.length - 1) == "\r")
			raw = raw.substr(0, raw.length - 1);
		return raw;
	}

	private inline function clamp(v:Int, lo:Int, hi:Int):Int {
		return v < lo ? lo : (v > hi ? hi : v);
	}
}
