Remove-Item hython.zip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path * -DestinationPath hython.zip -Force
haxelib submit hython.zip