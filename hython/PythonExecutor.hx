package hython;

#if sys
import sys.io.Process;
import sys.io.File;
import sys.FileSystem;
#end

/**
 * PythonExecutor - Execute actual Python scripts from Haxe/Hython code.
 * 
 * This class allows you to call Python functions from Haxe code by executing
 * Python scripts as external processes. Results are returned via stdout/stderr.
 * 
 * Requirements:
 * - Python must be installed and accessible via command line
 * - Works only on sys targets (C++, Neko, Java, C#, PHP, HashLink)
 * - Not supported on JavaScript, Flash, or other non-sys targets
 * 
 * Example:
 * ```haxe
 * var executor = new hython.PythonExecutor("python3");
 * 
 * if (executor.isAvailable()) {
 *     var result = executor.executeCode("print('Hello from Python!')");
 *     if (result.success) {
 *         trace(result.output);  // "Hello from Python!"
 *     }
 * }
 * ```
 */
class PythonExecutor {
    private var pythonPath:String;
    private var pythonArgs:Array<String>;
    
    #if sys
    private var eventBus:Dynamic; // EventBus type (optional, can be null)
    #end
    
    /**
     * Create a new PythonExecutor.
     * 
     * @param pythonPath Path to Python executable (e.g., "python3", "python", or full path)
     * @param eventBus Optional EventBus for event integration
     */
    public function new(?pythonPath:String, ?eventBus:Dynamic) {
        this.pythonPath = pythonPath != null ? pythonPath : "python";
        this.pythonArgs = [];
        
        #if sys
        this.eventBus = eventBus;
        #end
    }
    
    /**
     * Set the Python executable path.
     * 
     * @param path Path to Python executable
     */
    public function setPythonPath(path:String):Void {
        this.pythonPath = path;
    }
    
    /**
     * Check if Python is available and working.
     * 
     * @return True if Python can be executed successfully
     */
    public function isAvailable():Bool {
        #if sys
        try {
            var result = executeCode("import sys; print(sys.version)");
            return result.success;
        } catch (e:Dynamic) {
            return false;
        }
        #else
        return false;
        #end
    }
    
    /**
     * Get Python version string.
     * 
     * @return Python version string, or null if not available
     */
    public function getVersion():Null<String> {
        #if sys
        if (!isAvailable()) {
            return null;
        }
        
        try {
            var result = executeCode("import sys; print(sys.version.split()[0])");
            if (result.success) {
                return StringTools.trim(result.output);
            }
        } catch (e:Dynamic) {
            // Ignore
        }
        #end
        
        return null;
    }
    
    /**
     * Execute Python code string.
     * 
     * @param code Python code to execute
     * @param args Additional command-line arguments for Python
     * @return PythonResult with output, error, and exit code
     */
    public function executeCode(code:String, ?args:Array<String>):PythonResult {
        #if sys
        try {
            var tempFile = null;
            var scriptPath = null;
            
            // Create temporary Python file
            try {
                var timestamp = Std.int(Sys.time() * 1000);
                var random = Std.int(Math.random() * 10000);
                var tempDir = Sys.getEnv("TEMP");
                if (tempDir == null) tempDir = Sys.getEnv("TMP");
                if (tempDir == null) tempDir = ".";
                tempFile = tempDir + "/hython_" + 
                          Std.string(timestamp) + "_" + Std.string(random) + ".py";
                sys.io.File.saveContent(tempFile, code);
                scriptPath = tempFile;
            } catch (e:Dynamic) {
                // If temp file creation fails, try to execute directly via stdin
                return executeWithInput(code, "", args);
            }
            
            // Execute the script
            var result = execute(scriptPath, args);
            
            // Clean up temp file
            try {
                if (FileSystem.exists(scriptPath)) {
                    FileSystem.deleteFile(scriptPath);
                }
            } catch (e:Dynamic) {
                // Ignore cleanup errors
            }
            
            // Emit event if eventBus is available
            if (eventBus != null) {
                eventBus.emit("python:executed", {
                    success: result.success,
                    exitCode: result.exitCode,
                    hasOutput: result.output.length > 0,
                    hasError: result.error.length > 0
                });
            }
            
            return result;
        } catch (e:Dynamic) {
            var errorMsg = "Failed to execute Python code: " + Std.string(e);
            
            if (eventBus != null) {
                eventBus.emit("python:error", {error: errorMsg});
            }
            
            return {
                success: false,
                output: "",
                error: errorMsg,
                exitCode: -1,
                script: code
            };
        }
        #else
        return {
            success: false,
            output: "",
            error: "PythonExecutor is not supported on this target (sys target required)",
            exitCode: -1,
            script: code
        };
        #end
    }
    
    /**
     * Execute a Python script file.
     * 
     * @param scriptPath Path to Python script file
     * @param args Command-line arguments to pass to the script
     * @return PythonResult with output, error, and exit code
     */
    public function execute(scriptPath:String, ?args:Array<String>):PythonResult {
        #if sys
        try {
            if (!FileSystem.exists(scriptPath)) {
                return {
                    success: false,
                    output: "",
                    error: "Script file not found: " + scriptPath,
                    exitCode: -1,
                    script: scriptPath
                };
            }
            
            var processArgs = [scriptPath];
            if (args != null) {
                processArgs = processArgs.concat(args);
            }
            
            var process = new Process(pythonPath, processArgs);
            var output = process.stdout.readAll().toString();
            var error = process.stderr.readAll().toString();
            var exitCode = process.exitCode();
            process.close();
            
            var result:PythonResult = {
                success: exitCode == 0,
                output: output,
                error: error,
                exitCode: exitCode,
                script: scriptPath
            };
            
            // Emit event if eventBus is available
            if (eventBus != null) {
                eventBus.emit("python:executed", {
                    success: result.success,
                    exitCode: result.exitCode,
                    script: scriptPath,
                    hasOutput: result.output.length > 0,
                    hasError: result.error.length > 0
                });
            }
            
            return result;
        } catch (e:Dynamic) {
            var errorMsg = "Failed to execute Python script: " + Std.string(e);
            
            if (eventBus != null) {
                eventBus.emit("python:error", {error: errorMsg, script: scriptPath});
            }
            
            return {
                success: false,
                output: "",
                error: errorMsg,
                exitCode: -1,
                script: scriptPath
            };
        }
        #else
        return {
            success: false,
            output: "",
            error: "PythonExecutor is not supported on this target (sys target required)",
            exitCode: -1,
            script: scriptPath
        };
        #end
    }
    
    /**
     * Execute Python code with input via stdin.
     * 
     * @param code Python code to execute
     * @param input Input string to send to stdin
     * @param args Additional command-line arguments for Python
     * @return PythonResult with output, error, and exit code
     */
    public function executeWithInput(code:String, input:String, ?args:Array<String>):PythonResult {
        #if sys
        try {
            var processArgs = ["-c", code];
            if (args != null) {
                processArgs = processArgs.concat(args);
            }
            
            var process = new Process(pythonPath, processArgs);
            
            // Write input to stdin if provided
            if (input.length > 0) {
                process.stdin.writeString(input);
                process.stdin.close();
            }
            
            var output = process.stdout.readAll().toString();
            var error = process.stderr.readAll().toString();
            var exitCode = process.exitCode();
            process.close();
            
            var result:PythonResult = {
                success: exitCode == 0,
                output: output,
                error: error,
                exitCode: exitCode,
                script: code
            };
            
            // Emit event if eventBus is available
            if (eventBus != null) {
                eventBus.emit("python:executed", {
                    success: result.success,
                    exitCode: result.exitCode,
                    hasOutput: result.output.length > 0,
                    hasError: result.error.length > 0
                });
            }
            
            return result;
        } catch (e:Dynamic) {
            var errorMsg = "Failed to execute Python code with input: " + Std.string(e);
            
            if (eventBus != null) {
                eventBus.emit("python:error", {error: errorMsg});
            }
            
            return {
                success: false,
                output: "",
                error: errorMsg,
                exitCode: -1,
                script: code
            };
        }
        #else
        return {
            success: false,
            output: "",
            error: "PythonExecutor is not supported on this target (sys target required)",
            exitCode: -1,
            script: code
        };
        #end
    }
}

/**
 * Result structure returned by PythonExecutor methods.
 */
typedef PythonResult = {
    /**
     * True if execution was successful (exit code 0).
     */
    success:Bool,
    
    /**
     * Standard output from Python execution.
     */
    output:String,
    
    /**
     * Standard error output from Python execution.
     */
    error:String,
    
    /**
     * Process exit code (0 = success, non-zero = error).
     */
    exitCode:Int,
    
    /**
     * The script or code that was executed.
     */
    script:String
}

