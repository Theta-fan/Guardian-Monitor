#Staking address
$ActiveGnAddress = "0x000000000000000000000000000" #<--- Enter your Guardian Node staking address here as it appears on the Guardian Node

#Show Disclaimer
Clear-Host
Write-Host "This software and associated documentation files, the 'Software',"
Write-Host "will hereby be referred to as such."
Write-Host " "
Write-Host "THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,"
Write-Host "EXPRESS OR IMPLIED, INCLUDING BUT NOTLIMITED TO THE WARRANTIES"
Write-Host "OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND"
Write-Host "NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT"
Write-Host "HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,"
Write-Host "WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING"
Write-Host "FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR"
Write-Host "OTHER DEALINGS IN THE SOFTWARE."
Write-Host " "
Write-Host "Press any key to accept and continue..."

#Wait for any key to continue
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

#Cleanup from last attempts
remove-variable x -ea SilentlyContinue
remove-variable WebInfo -ea SilentlyContinue
remove-variable Tfuel -ea SilentlyContinue
remove-variable TFuelNow -ea SilentlyContinue
remove-variable TFuelDiff -ea SilentlyContinue
remove-variable TfuelStart -ea SilentlyContinue
remove-variable TFuelTotal -ea SilentlyContinue

#Create the web client
$WebClient = new-object system.net.webclient

#Display meessage
Clear-Host
Write-Host "Guardian Monitor rewards tool V1.000"
Write-Host "Now actively checking address: $ActiveGnAddress"
Write-Host ""

#Loop forever
while($true)
{
    #Time counter
    $x++
    
    #Clear last result
    $WebInfo = $null
    
    #Loop until theta explorer responds
    While($WebInfo -eq $null)
    {
        #Catch errors
        try
        {        
            #Get the staking address info from theta explorer and convert from json
            $WebInfo = $WebClient.DownloadString("https://guardian-testnet-explorer.thetatoken.org:9000/api/stake/$($ActiveGnAddress)?hasBalance=true") | ConvertFrom-Json
        
            #Is TFuel field null?
            if ($WebInfo.body.holderrecords.source_tfuelwei_balance -eq $null)
            {
                #Yes, throw error
                throw
            }
        }
        catch
        {
            #Display error
            Write-Host -NoNewline "`r$(Get-Date) - Error, unable to get TFuel balance. Will retry."

            #Clear last result
            $WebInfo = $null
            
            #Wait 10 seconds
            sleep 10
        }
    }

    #Pull out the TFuel value
    $TFuelNow = $WebInfo.body.holderrecords.source_tfuelwei_balance
    
    #Cutoff last 17 digits
    $TFuelNow = $TFuelNow.SubString(0,($TFuelNow.Length - 17))
    
    #Divide by 10
    $TFuelNow = ([int64]$TFuelNow/10)
    
    #Is $TFuel null?
    If ($Tfuel -eq $null)
    {
        #Yes, set equal
        $Tfuel = $TFuelNow

        #Remember starting value
        $TfuelStart = $TFuelNow
    }
    
    #Get the difference
    $TFuelDiff = $TFuelNow - $Tfuel 

    #Did we earn more than 1 TFuel?
    if ($TFuelDiff -gt 1)
    {
        #Yes, format Tfuel
        $TFuelDiff = $TFuelDiff.ToString('#0.0')

        #Calculate total TFuel earned
        $TFuelTotal = $TfuelNow - $TfuelStart

        #Format total TFuel earned
        $TFuelTotal = $TFuelTotal.ToString('#0.0')

        #Display success status
        Write-Host -NoNewline "`r$(Get-Date) - Success, TFuel earned $TFuelDiff. (Total: $TFuelTotal)"
        Write-Host ""

        #Zero out starting TFuel balance
        $Tfuel = $TFuelNow
            
        #Reset timer
        $x = 0

        #Display progress update
        Write-Host -NoNewline "`r$(Get-Date) - Waiting...$x of 17 minutes"
    }
    else
    {
        #Has more than 17 minutes passed
        if ($x -gt 17)
        {
            #Yes, display failure status
            Write-Host -NoNewline "`r$(Get-Date) - Failure, Guardian Node is not earning rewards *** Warning ****"
            Write-Host ""

            #Zero out starting TFuel balance
            $Tfuel = $TFuelNow
                
            #Reset timer
            $x = 0
        }
        else
        {
            #Display progress update
            Write-Host -NoNewline "`r$(Get-Date) - Waiting...$x of 17 minutes"
        }
    }
    
    #Wait a minute
    sleep 60
}