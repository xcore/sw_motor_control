--Descriptive metadata

componentName = "dsc_adc_dualsample"
componentFullName = "Dual Sample ADC Interface for DSC Applications"
alternativeNames = { "ADC" }
componentDescription = "This is an ADC interface server component for motor control applications in which the current in two coils must be measured simultaneously."
componentDomainTags = {"Motor Control",  "Advanced Motor Control", "Analog", "ADC"} 
componentApplicationTags = {"Motor Control"} 
componentVersion = "0v1"

--Component parameters

configPoints = {
  numClients = { 
    short   = "Number of client Threads",
    long    = "The number of client threads that will interact with the ADC server component",
    help    = "",
    units   = "",
    sortKey = 1,
    paramType = "int",
    max = 4,
    min = 1,
    default = 1
  },
  adcPartNumber = {
    short   = "External ADC to target",
    long    = "Select an ADC part from the list",
    help    = "This component is designed to handle the differing serial interfaces on the parts enumerated in the list. For early design exploration it doesn't matter which one is picked because the resource usage and interface presented to the ADC client threads is not materially changed by the selection.",
    units   = "",
    sortKey = 1,
    paramType = "enum",
    options = { "AD7265", "MAX1379", "LTC1408"},
    default = "AD7265"
  },
  lockToExternal = {
    short   = "Lock To External Tigger",
    long    = "Set to locked if ADC server is to be triggered by external event. The 1379 cmoponent does not offer this option.",
    help    = "The XMOS motor controlplatform locks the ADC to the PWM cycle, thus the trigger event comes from the PWM server",
    units   = "",
    sortKey = 1,
    paramType = "enum",
    options = { "Locked", "Not Locked"},
    default = 1
  }
}
--Build configurations

configSets = {
}

--Resource Metadata

function getStaticMemory()
  return 1024
end

function getDynamicMemory()
  return 0
end

function getNumberOfChanEndArguments()
  basechans = 1
  if component.params.lockToExternal == "Locked" then 
    basechans=2
  end
  return component.params.numClients * baseChans
end

function getNumberOfInternalChanEnds()
  return 0
end

function getNumberOfTimers()
  return 1
end

function getNumberOfClockBlocks()
  return 1
end

function getNumberOfLocks()
  return 0
end

function getNumberOfThreads()
  return 1
end

function getNumberOf1BitPorts()
  local base1bports = 3
  if component.params.adcPartNumber == "AD7265" then
    base1bports = base1bports + 2
  elseif component.params.adcPartNumber == "MAX1379" then
    base1bports = base1bports + 2
  elseif component.params.adcPartNumber == "LTC1408" then
    base1bports = base1bports + 1
  end
end

function getNumberOf4BitPorts()
  return 0
end

function getNumberOf8BitPorts()
  return 0
end

function getNumberOf16BitPorts()
  return 0
end

function getNumberOf32BitPorts()
  return 0
end

--Timing Metadata

function getMinimumThreadSpeed()
  return 25
end

--Qualification Metadata

function isValid()
  return 1
end

function getDerivedVariables()
  derivedVariables = {}

  if component.params.adcPartNumber == "AD7265" then
    derivedVariables.status = "general"      
    derivedVariables.samples_per_second = "1 MSPS"      
  elseif component.params.adcPartNumber == "MAX1379" then
    derivedVariables.status = "example"      
    derivedVariables.samples_per_second = "1.25 MSPS"      
  elseif component.params.adcPartNumber == "LTC1408" then
    derivedVariables.status = "general"        
    derivedVariables.samples_per_second = "600 KSPS"        
  end  
  return derivedVariables
end


--Project Generation Metadata

function getIncludes() 
  return 0
end

function getGlobals()
  return 0
end

function getChannels()
  return 0
end

function getLocals()
  return 0
end

function getCalls()
  return 0
end

--Datasheet Generation Metadata

function getPortName(i)
  if component.params.adcPartNumber == "AD7265" or component.params.adcPartNumber == "MAX1739" then
    if i == 1 then return "ADC_" .. component.id .. "_SCK"
    elseif i == 2 then return "ADC_" .. component.id .. "_CONVST"
    elseif i == 3 then return "ADC_" .. component.id .. "_SEL"
    elseif i == 4 then return "ADC_" .. component.id .. "_DATA0"
    elseif i == 5 then return "ADC_" .. component.id .. "_DATA1"
    else return 0
    end
  elseif component.params.adcPartNumber == "LTC1408" then
    if i == 1 then return "ADC_" .. component.id .. "_SCK"
    elseif i == 2 then return "ADC_" .. component.id .. "_CONVST"
    elseif i == 3 then return "ADC_" .. component.id .. "_SEL"
    elseif i == 4 then return "ADC_" .. component.id .. "_DATA"
    else return 0
    end
  else
    return 0
  end
end

function getPortDescription(i)
  if i == 1 then return "ADC Serial Data Clock for " .. component.id 
  elseif i == 2 then return "ADC Conversion Strobe for " .. component.id 
  elseif i == 3 then return "ADC Channel Select for " .. component.id 
  elseif i == 4 then return "ADC Serial Data Output 0 for " .. component.id 
  elseif i == 5 then return "ADC Serial Data Output 1 for " .. component.id 
  end
end

function getPortDirection(i)
  if i == 1 then return "out"
  elseif i == 2 then return "out"
  elseif i == 3 then return "out"
  elseif i == 4 then return "in"
  elseif i == 5 then return "in"
  end
end

function getDatasheetSummary()
  return "Dual Sample and Hold ADC Interface Server that can be triggered from another thread" 
end

function getDatasheetDescription()
  return [[This is an ADC interface server component for motor control applications in which the current in two coils must be measured simultaneously. The ADC returns the sampled data to the thread using a serial clock that is enabled following assertion of the conversion strobe by the thread. Optionally the server can accept an external trigger over a channel end, which is typically used to synchronise the sampling point to the PWM cycle. This component currently directly supports the serial interfaces and architecture of three suitable external ADC components, the AD7265, MAX1739 and LTC1408 which between them cover sample rates between 1.25 MSAP and 600 KSPS, but could easily be modified to accomodate alternative ADCs.]]    
end
