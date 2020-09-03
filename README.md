# powershellJobManager

# Usage

Start-Parallel -JobGroup "NAME" -numerOfJobs 10 -JobRef "RefName" -ArgumentList @($argument1, $argument 2) -ScriptBlock $ScriptBlock

$ScriptBlock should define the code to execute by each job.
