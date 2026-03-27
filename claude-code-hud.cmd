@echo off
:: Windows launcher for claude-code-hud
:: Place this file and claude-code-hud in the same directory.
:: Point statusLine.command at this .cmd file.
python "%~dp0claude-code-hud" %*
