# PlayStation Network Entitlements

Sony has an API for retrieving the entitlements of a PlayStation Network account. Entitlements represent all of the content and licenses an account owns (free, paid, or leased via subscription).  

This repository contains Bash and PowerShell scripts for querying this API and exporting the JSON response data to a file.  

It also contains a simple HTML page for parsing the data in this file into a more accessible table view. All processing on the file is performed locally in your browser; best experience is with a desktop browser.  

A hosted version of this page is available via GitHub Pages:  
https://andshrew.github.io/PlayStation-Entitlements

# Usage

## Download Account Entitlement Data

Download your accounts entitlement data using either the Bash or PowerShell scripts. This requires authentication to your PlayStation Network account. These scripts mimic the way that the PlayStation App authenticates requests to Sony's API.

1. In your web browser access https://store.playstation.com and log in with a PSN account.  

2. In the same browser access https://ca.account.sony.com/api/v1/ssocookie  
You should see a response with npsso followed by a string of letters and numbers. Highlight and copy this. You will be prompted to paste this into the script. Do not include the "quotes" when pasting the value.
![](assets/img/2021-03-20-15-33-08.png)

### Bash (Linux, MacOS, Unix)

> The script is tested against Bash and requires both [curl](https://curl.se) for submitting web requests, and [jq](https://jqlang.org) for processing the JSON data response. If jq is not installed on your system see https://jqlang.org/download/ for installation instructions.  

1. Download the latest version of `psn-entitlements.sh`:  
https://github.com/andshrew/PlayStation-Entitlements/releases/latest

2. Mark the downloaded file as executable:  
`chmod +x psn-entitlements.sh`

3. Run the script:  
`./psn-entitlements.sh`

### PowerShell (Windows, Linux, MacOS)

> The script is tested against Windows PowerShell (included with Windows) and PowerShell (available for download from https://github.com/PowerShell/PowerShell)

1. Download the latest version of `psn-entitlements.ps1`:  
https://github.com/andshrew/PlayStation-Entitlements/releases/latest

2. Run `powershell.exe` (Windows PowerShell) or `pwsh` (PowerShell). Navigate to the folder where you downloaded the script.

3. **_Windows Only_**  
Most default configurations of PowerShell restrict running of scripts under Windows. You can enable the execution of all scripts for the current session by running command:  
`Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

4. Run the script:  
`.\psn-entitlements.ps1`

## View Entitlement Data

You should now have a file containing your entitlement data.  

By default on Windows this will have been saved to your User Profile folder (eg. `C:\Users\username`), and on Linux/MacOS/Unix saved to your Home folder (eg. `/home/username`).

You can view the contents in any Text Editor, or import in to software which supports parsing JSON data.  

A simple HTML/JavaScript based parser is included in this repository. You can access a hosted version of it on GitHub pages:  
https://andshrew.github.io/PlayStation-Entitlements

Alternatively, download the latest version of `index.html`:  
https://github.com/andshrew/PlayStation-Entitlements/releases/latest

This file can be opened directly in your browser.  

Click `Choose File` and select the file created by the script. Your data will be parsed into a table, which can be sorted or filtered. Clicking a row will display additional information about that specific entitlement.  

Whichever option you use, processing of the data is performed locally by your browser.

# Additional Information

See the Wiki for additional information:  
https://github.com/andshrew/PlayStation-Entitlements/wiki

The content of this repository is not affiliated with PlayStation or Sony Interactive Entertainment Inc.

Unless otherwise stated:-

* All code is licensed under the MIT License.  

* All written content (eg. [Wiki](https://github.com/andshrew/PlayStation-Entitlements/wiki)) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).