package paopao.hython;

class Preprocessor {
	private static var trailingWhitespace = ~/[ \t]+$/;
	private static var onlyWhitespace = ~/^[ \t]*$/;

	/**
	 * Clean up the input source code before lexing
	 * - Removes comments (# Comment)
	 * - Removes unnecessary whitespace (tabs/spaces)
	 */
	public static function preprocess(input:String):String {
		var lines = input.split('\n');
		var cleaned:Array<String> = [];

		for (line in lines) {
			// Remove comments from the line
			line = removeComment(line);

			// Skip lines that are now only whitespace
			if (isOnlyWhitespace(line)) {
				continue;
			}

			cleaned.push(line);
		}

		return cleaned.join('\n');
	}

	/**
	 * Remove comment from a line (everything after #)
	 * Handle strings properly - don't remove # inside strings
	 */
	private static function removeComment(line:String):String {
		var result = new StringBuf();
		var inString = false;
		var stringChar = '';

		for (i in 0...line.length) {
			var ch = line.charAt(i);

			// Count preceding backslashes
			var backslashCount = 0;
			var j = i - 1;
			while (j >= 0 && line.charAt(j) == '\\') {
				backslashCount++;
				j--;
			}

			var isEscaped = (backslashCount % 2 == 1);

			if ((ch == '"' || ch == "'") && !isEscaped) {
				if (!inString) {
					inString = true;
					stringChar = ch;
				} else if (ch == stringChar) {
					inString = false;
				}
				result.add(ch);
			} else if (ch == '#' && !inString) {
				break;
			} else {
				result.add(ch);
			}
		}

		// Only trim if not inside a string
		return trailingWhitespace.replace(result.toString(), '');
	}

	/**
	 * Check if line contains only whitespace (spaces, tabs)
	 */
	private static function isOnlyWhitespace(line:String):Bool {
		return ~/^[ \t]*$/.match(line);
	}
}
