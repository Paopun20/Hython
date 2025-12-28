$zip = "hython.zip"

Remove-Item $zip -Force -ErrorAction SilentlyContinue

Compress-Archive `
  -Path paopao, haxelib.json, README.md `
  -DestinationPath $zip `
  -Force

haxelib submit $zip
