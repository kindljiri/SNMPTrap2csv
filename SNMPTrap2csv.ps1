<#  
.SYNOPSIS  
    This script select traps from MIB file and convert it into csv (for better presentation to customer/manager ;-).
.DESCRIPTION  
    This script select traps from MIB file and convert it into csv (for better presentation to customer/manager ;-).
.NOTES  
    File Name      : SNMPTraps2csv.ps1  
    Author         : Jiri Kindl; kindl_jiri@yahoo.com
    Prerequisite   : PowerShell V2 over Vista and upper.
    Copyright 2017 - Jiri Kindl
.LINK  
    
.EXAMPLE  
    .\SNMPTraps2csv.ps1 -inputfile mib_file.mib
#>

#pars parametrs with param
param([string]$inputfile = "default")

Function usage {
  "SNMPTraps2csv.ps1 -inputfile mib_file.mib"
  "inputfile - policy file"
  exit
}


try {
  $lines=get-content $inputfile -ErrorAction Stop
  $sa_status="init"
  $trap_name = ""
  $status = ""
  $description = ""
  $objects = ""
  $ID = ""
  $parent = ""

  #print header
  "Trap name;Description/Variables;Objects;Status;ID;Parent ID"

  
  Foreach ($line in $lines) {
    $line = $line.trim()
    #ignore line containings only comment
    #DEBUG:"$sa_status"
    if ($line.startswith("--")) {
      continue
    }
    elseif ($sa_status -eq "init") {
      if ($line -cmatch "NOTIFICATION-TYPE"){
        $sa_status = "process_notification"
        $trap_name = $line -replace "NOTIFICATION-TYPE"
        $trap_name = $trap_name.trim() 
        continue
      }
      elseif ($line -cmatch "IMPORTS") {
        $sa_status = "process_imports"
        continue
      }
      elseif ($line -cmatch "TRAP-TYPE") {
        $sa_status = "process_trap"
        $trap_name = $line -replace "TRAP-TYPE"
        $trap_name = $trap_name.trim()
        continue
      } 

    }
    
    elseif ($sa_status -eq "process_trap"){
      if ($line -cmatch "DESCRIPTION"){
        $description = $description + $line
        $description = $description -replace "DESCRIPTION", ""
        $description = $description.trim()
        if (!($line.EndsWith('"'))){
          $sa_status = "process_trap_description"
        }
        continue
      }
      elseif ($line -cmatch "VARIABLES"){
        $objects = $objects + $line
        $objects = $objects -replace "VARIABLES", ""
        if (!($line.EndsWith('}'))){
          $sa_status = "process_variables"
        }
        continue
      }
      elseif ($line -cmatch "ENTERPRISE"){
        $parent = $line -replace "ENTERPRISE", ""
        $parent = $parent.trim()
        continue
      }
      elseif ($line -Match "::="){
        $ID = $line -replace "::=", ""
        $ID = $ID.trim()
        "$trap_name;$status;$description;$objects;$ID;$parent"
        $sa_status="init"
        $trap_name = ""
        $status = ""
        $description = ""
        $objects = ""
        $ID = ""
        $parent = ""
        continue
      }
    }
    elseif ($sa_status -eq "process_notification"){
      if ($line -cmatch "DESCRIPTION"){
        $description = $line -replace "DESCRIPTION", ""
        $description = $description.trim()
        if (!($line.EndsWith('"'))){
          $sa_status = "process_description"
        }
        continue
      }
      elseif ($line -cmatch "OBJECTS"){
        $objects = $line -replace "OBJECTS", ""
        $objects = $objects.trim()
        if (!($line.EndsWith('}'))){
          $sa_status = "process_objects"
        }
        continue
      }
      elseif ($line -Match "::="){
        $parent_and_id = $line -replace "::=", ""
        $parent_and_id = $parent_and_id -replace "{", "" 
        $parent_and_id = $parent_and_id -replace "}", ""
        $parent_and_id = $parent_and_id.trim()
        ($ID,$parent)  = ($parent_and_id -split " ")
        "$trap_name;$status;$description;$objects;$ID;$parent"
        $sa_status="init"
        $trap_name = ""
        $status = ""
        $description = ""
        $objects = ""
        $ID = ""
        $parent = ""
        continue
      }
    }
    elseif ($sa_status -eq "process_description"){
      if ($line.EndsWith('"')){
        $description = $description + ' ' + $line
        $sa_status = "process_notification"
        continue
      }
      else {
        $description = $description + ' ' + $line
        continue
      }
    }
    elseif ($sa_status -eq "process_trap_description"){
      if ($line.EndsWith('"')){
        $description = $description + ' ' + $line
        $sa_status = "process_trap"
        continue
      }
      else {
        $description = $description + ' ' + $line
        continue
      }
    }
    elseif ($sa_status -eq "process_objects"){
      if ($line.EndsWith('}')){
        $objects = $objects + $line
        $sa_status = "process_notification"
        continue
      }
      else {
        $objects = $objects + ' ' + $line
        continue
      }
    }
    elseif ($sa_status -eq "process_variables"){
      if ($line.EndsWith('}')){
        $objects = $objects + $line
        $sa_status = "process_trap"
        continue
      }
      else {
        $objects = $objects + ' ' + $line
        continue
      }
    }
    elseif ($sa_status -eq "process_imports"){
      if ($line.EndsWith(';')){
        $sa_status = "init"
        continue
      }
    }
  }
}


catch [System.Management.Automation.ItemNotFoundException] {
  "No such file"
  ""
  usage
}
catch {
  $Error[0]
}

