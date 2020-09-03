Function Start-Parallel 
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $false)]
		[int]$numberOfJobs = 8,

		[Parameter(Mandatory = $false)]
		[string]$JobGroup = "DEFAULT",

		[Parameter(Mandatory = $false)]
		[string]$JobRef = "",

		[Parameter(Mandatory = $true)]
		[scriptblock]$ScriptBlock,

		[Parameter(Mandatory = $false)]
		[array]$ArgumentList = @()
	)

	if ($jobRef -eq "") {
		$jobId = "$JobGroup $(new-guid)"
	} else {
		$jobId = "$JobGroup $JobRef"
	}
	$jobs = get-job -state Running | where-object { $_.name -match "^$JobGroup" }
	while ($jobs.Count -ge $numberOfJobs) {
		start-sleep 1
		$jobs = get-job -state Running | where-object { $_.name -match "^$JobGroup" }
		write-verbose ($jobs | out-string)
	}

	if ($ArgumentList.Count -eq 0) {
		start-job -name $jobId -scriptblock $ScriptBlock | out-null
	} else {
		start-job -name $jobId -scriptblock $ScriptBlock -ArgumentList $ArgumentList | out-null
	}
}

#------------------------------------------------------------------------------
Function Complete-Parallel 
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $false)]
		[string]$JobGroup = "DEFAULT"
	)

	$jobs = get-job -state Running | where-object { $_.name -match "^$JobGroup" }
	while ($jobs.Count -gt 0) {
		start-sleep 1
		$jobs = get-job -state Running | where-object { $_.name -match "^$JobGroup" }
		write-verbose ($jobs | out-string)
	}

	$(get-job -state Completed) | where-object { $_.name -match "^$JobGroup" } | foreach-object {
		try {
			$out = receive-job $_ 2>&1 -ErrorAction Stop | out-string
		}
		catch {
			Write-Warning "Unable to register DLL."
			Write-Warning $_.Exception
		}
		
		[PSCustomObject]@{
			"Job" = $_.name
			"StartTime" = $_.PSBeginTime
			"EndTime" = $_.PSEndTime
			"State" = $_.State
			"Output" = $out
		}
		remove-job $_ | out-null
	}

    $(get-job -state Failed) | where-object { $_.name -match "^$JobGroup" } | foreach-object {
	$out = receive-job $_ 2>&1 | out-string
		[PSCustomObject]@{
			"Job" = $_.name
			"StartTime" = $_.PSBeginTime
			"EndTime" = $_.PSEndTime
			"State" = $_.State
			"Output" = $out
		}
		remove-job $_ | out-null
	}
}

#------------------------------------------------------------------------------
Export-ModuleMember -Function Start-Parallel
Export-ModuleMember -Function Complete-Parallel
