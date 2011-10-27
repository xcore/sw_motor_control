--Descriptive metadata

componentName = "dsc_qei"
componentFullName = "Quadrature Encoder Interface"
alternativeNames = { "QEI" }
componentDescription = "Quadrature Encoder Interface (ABI) for motor control applications"
componentDomainTags = {"Communications",  "CAN"} 
componentApplicationTags = {"Industrial Networking", "Motor Control"} 
componentVersion = "0v1"

--Component parameters

configPoints = {
  numClients = {
    short   = "Number of client threads",
    long    = "Defines how many threads use the client library to obtani information from the qei server",
    help    = "",
    units   = "",
    sortKey = 1,
    paramType = "int",
    max     = 3,
    min     = 1,
    default = 1
  },
  lineCount = {
    short   = "Line Count",
    long    = "Defines how many edges in total are output by the encoder in one full revolution on the A and B quadrature signals.",
    help    = "",
    units   = "",
    sortKey = 1,
    paramType = "int",
    max     = 2048,
    min     = 256,
    default = 1024
  },
}
--Build configurations

configSets = {
}

--Resource Metadata

function getStaticMemory()
  return 512
end

function getDynamicMemory()
  return 0
end

function getNumberOfChanEndArguments()
  return 1
end

function getNumberOfInternalChanEnds()
  return 0
end

function getNumberOfTimers()
  return 1
end

function getNumberOfClockBlocks()
  return 0
end

function getNumberOfLocks()
  return 0
end

function getNumberOfThreads()
  return 1
end

function getNumberOf1BitPorts()
  return 2
end

function getNumberOf4BitPorts()
  return 1
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
    return "QENC_" .. component.id 
end

function getPortDescription(i)
  return "Quadrature encoder interface"
end

function getPortDirection(i)
  return "in"
end

function getDatasheetSummary()
  return "Quadrature Encoder Interface for DSC Applications"
end

function getDatasheetDescription()
  return [[The quadrature encoder input (QEI) module is provided with a library for both running
the thread that handles the direct interface to the pins and also for retrieving and
calculating the appropriate information from that thread.
The particular interface that is implemented utilises three signals comprising of two
quadrature output (A and B) and an index output (I). A and B provide incremental
information while I indicates a return to 0 or origin. The signals A and B are provided
out of phase so that the direction of rotation can be resolved.]]
end
