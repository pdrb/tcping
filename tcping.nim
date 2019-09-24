# tcping 0.1
# author: Pedro Buteri Gonring
# email: pedro@bigode.net
# date: 20190924

import
  nativesockets, net, os, parseopt, sequtils, strformat, strutils, times


const tcpingVer = "0.1"

# Create a custom KeyboardInterrupt Exception for handle ctrl-c
type
  KeyboardInterrupt = object of Exception


# Show the program usage options
proc printHelp(opts: tuple) =
  quit("""Usage: tcping host [options]

ping hosts using tcp packets, e.g., 'tcping example.org'

Options:
  -v, --version   show program's version number and exit
  -h, --help      show this help message and exit
  -t              ping host until stopped with 'control-c'
  -n:count        number of requests to send (default: $1)
  -p:port         port number to use (default: $2)
  -w:timeout      timeout in milliseconds to wait for reply
                  (default: $3)
""".format(opts.count, opts.port, opts.timeout), QuitSuccess)


# Parse and validate a positive integer
proc parsePositiveInt(val: string): int =
  let number = parseInt(val)
  if number < 1:
    raise newException(ValueError, "'$1' is not a positive integer" % $number)
  return number


# Parse and validate arguments
proc parseOpts(): tuple =
  var args = newSeq[string]()
  var options = (
    host: "",
    count: 4,
    port: 80,
    timeout: 3000,
    t: false
  )

  if paramCount() == 0:
    printHelp(options)

  let validOpts = ["v", "version", "h", "help", "t", "n", "p", "w"]

  let numErrorMsg = "Error: problem parsing '-$1' option, " &
                    "'$2' must be a positive integer"

  var p = initOptParser()
  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      args.add(key)
    of cmdLongOption, cmdShortOption:
      if key notin validOpts:
        quit("Error: invalid option '$1', use 'tcping -h' for help" % key)
      case key
      of "v", "version":
        quit(tcpingVer, QuitSuccess)
      of "h", "help":
        printHelp(options)
      of "n":
        if val == "":
          quit("Error: count needs a value, e.g., '-n:10'")
        try:
          options.count = parsePositiveInt(val)
        except:
          quit(numErrorMsg % [key, val])
      of "p":
        if val == "":
          quit("Error: port needs a value, e.g., '-p:22'")
        try:
          options.port = parsePositiveInt(val)
        except:
          quit(numErrorMsg % [key, val])
        if options.port > 65535:
          quit("Error: port must be a number between 1 and 65535")
      of "w":
        if val == "":
          quit("Error: timeout needs a value, e.g., '-w:1000'")
        try:
          options.timeout = parsePositiveInt(val)
        except:
          quit(numErrorMsg % [key, val])
      of "t":
        if val == "":
          options.t = true
        else:
          quit("Error: t option does not need a value, use just '-t'")
    of cmdEnd:
      discard

  if args.len != 1:
    quit("Error: tcping needs 1 argument, use 'tcping -h' for help")
  options.host = args[0]

  return options


# Get host ip
proc getIp(host: string): string =
  var ip: string
  try:
    ip = getHostByName(host).addrList[0]
  except:
    quit(&"Error: unknown host {host}")
  return ip


# Ping host using tcp socket, timeout and return latency in milliseconds
proc ping(host: string, port: int = 80, timeout: int = 3000): float =
  let s = newSocket()
  let initTime = epochTime()
  try:
    s.connect(host, Port(port), timeout)
  except OSError:
    let errorMsg = getCurrentExceptionMsg()
    # Refused in error means host is alive, otherwise quit
    if "refused" notin errorMsg:
      quit("Error: $1" % errorMsg)
  let endTime = epochTime()
  s.close()
  return (endTime - initTime) * 1000


# Handler to raise exception for ctrl-c
proc ctrlcHandler() {.noconv.} =
  raise newException(KeyboardInterrupt, "Keyboard Interrupt")


# Main procedure
proc main() =
  let opts = parseOpts()
  # Set a hook to handle ctrl-c
  setControlCHook(ctrlcHandler)
  # We pass the ip to ping proc to avoid dns lookup getting computed
  let hostIp = getIp(opts.host)

  # Vars
  var latencys = newSeq[float]()
  var latency: float
  var rcvd = 0
  var sent = 0

  # Print appropriate beginning message
  if not opts.t:
    echo &"\nPinging {opts.host} {opts.count} times on port {opts.port}:\n"
  else:
    echo &"\nPinging {opts.host} on port {opts.port}:\n"

  # Main loop
  try:
    while true:
      try:
        latency = ping(hostIp, opts.port, opts.timeout)
        latencys.add(latency)
        inc(rcvd)
        inc(sent)
        echo &"Reply from {hostIP}:{opts.port} time={latency:.2f} ms"
      except TimeoutError:
        inc(sent)
        echo &"Timed out after {opts.timeout} milliseconds"
      # End loop if needed
      if not opts.t:
        if sent == opts.count:
          break
      # Sleep between requests
      sleep(1000)
  except KeyboardInterrupt:
    echo "\nAborted."

  # Handle early exit during first packet timeout
  if sent == 0:
    quit()

  # If no packets received print appropriate message and quit
  if rcvd == 0:
    echo "\nDidn't receive any packets..."
    echo "Host is probably DOWN or firewalled. Sorry :'(\n"
    quit()

  # Calculate average latency time
  let sumLatency = foldl(latencys, a + b)
  let avgLatency = sumLatency / rcvd.float

  # Print summary
  echo "\nStatistics:"
  echo "-".repeat(26)
  echo &"\nHost: {opts.host}\n"
  echo &"Sent: {sent} packets\nReceived: {rcvd} packets"
  echo &"Lost: {sent - rcvd} packets ({(sent - rcvd) / sent * 100:.2f}%)\n"
  echo &"Min latency: {latencys.min:.2f} ms"
  echo &"Max latency: {latencys.max:.2f} ms"
  echo &"Average latency: {avgLatency:.2f} ms\n"


when isMainModule:
  main()
