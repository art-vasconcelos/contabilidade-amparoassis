@echo off
rem Paliativo de 27/10/2026: um segundo aparelho responde como 192.168.0.1 (MAC 50-91-E3-3F-00-51)
rem e a maquina perde a internet. Fixa o MAC do ER605 para o gateway nesta maquina.
rem Executar com botao direito > Executar como administrador.
rem Desfazer depois de resolver o aparelho intruso:
rem   Remove-NetNeighbor -IPAddress 192.168.0.1 -Confirm:$false
powershell -NoProfile -ExecutionPolicy Bypass -Command "$i=(Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select-Object -First 1).InterfaceIndex; Remove-NetNeighbor -InterfaceIndex $i -IPAddress 192.168.0.1 -Confirm:$false -ErrorAction SilentlyContinue; New-NetNeighbor -InterfaceIndex $i -IPAddress 192.168.0.1 -LinkLayerAddress 98-BA-5F-AB-E3-54 -State Permanent; ipconfig /flushdns; ping -n 3 8.8.8.8; nslookup google.com"
pause
