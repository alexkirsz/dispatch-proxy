import program from "commander";
import Logger from "tmpl-log";
import OS from "os";

const logger = new Logger({ tab: 10, gutter: " " })
  .registerTag("b", ["bold"])
  .registerEvent("echo", "<b>echo");

program.version(require("../package.json").version);


// not sure what this does..
program.command("echo <arg>").action(arg => {
  logger.emit("echo", `echoing "${arg}"`);
});

program
  .command('list')
  .description('list all available network interfaces')
  .action(function() {
    const interfaces = OS.networkInterfaces();
    console.log("listing interfaces:\n");

    //iterate all interfaces, e.g. en0
    for (let name in interfaces) {
      logger.log (`<b> ${name}`);

      //iterate all sub-interfaces inside each interface
      for (let i = 0; i < interfaces[name].length; i++) {
        let subInterface = interfaces[name][i];
        let subInterfaceAddress = interfaces[name][i].adress;

        //IP address, IP protocal, internal or external
        let { address, family, internal } = subInterface;
        if (internal === true) {
          internal = 'Internal';
        } else internal = 'External';
        logger.log (`     ${address} (${family}, ${internal})\n`);

      }
    }
  });

program
  .command('start')
  .usage('[options] [addresses]')
  .description('start a proxy server')
  .option('-H, --host <h>', 'which host to accept connections from (defaults to localhost)', String)
  .option('-p, --port <p>', 'which port to listen to for connections (defaults to 8080 for HTTP proxy, 1080 for SOCKS proxy)', Number)
  .option('--http', 'start an http proxy server', Boolean)
  .option('--debug', 'log debug info in the console', Boolean)
  .action (function(args) {
    const interfaces = OS.networkInterfaces();

    //map from args
    let {port, host, http, https, debug} = args;
    //optional object
    const argObject = {port: port, host: host, http: http, https: https, debug: debug};

    //includes all IP addresses that can be used for dispatching traffic
    let addresses = [];
    for (let name in interfaces) {
      for (let i = 0; i < interfaces[name].length; i++) {
        let subInterface = interfaces[name][i];
        let subInterfaceAddress = interfaces[name][i].adress;

        let { address, family, internal } = subInterface;
        if (family === 'IPv4' & internal === false) {
          //push to array
          addresses.push(address);
        }

      }
    }

    //start http proxy
    if (http) {
      port = port || 8080;
      type = 'HTTP';

      // waiting for http.js
    //   proxy = new HttpProxy addresses, port, host
    //
    //   proxy
    //     .on 'request', ({ clientRequest, serverRequest, localAddress }) ->
    //       id = (crypto.randomBytes 3).toString 'hex'
    //
    //       logger.emit 'request', "[#{id}] <a>#{clientRequest.url}</>"
    //       logger.emit 'dispatch', "[#{id}] <a>#{localAddress}</>"
    //
    //       serverRequest
    //         .on 'response', (serverResponse) ->
    //           logger.emit 'response', "[#{id}] <magenta><b>#{serverResponse.statusCode}</></>"
    //
    //         .on 'error', (err) ->
    //           logger.emit 'error', "[#{id}] clientRequest\n#{escape err.stack}"
    //
    //         .on 'end', ->
    //           logger.emit 'end', "[#{id}] serverRequest"
    //
    //       clientRequest
    //         .on 'error', (err) ->
    //           logger.emit 'error', "[#{id}] clientRequest\n#{escape err.stack}"
    //
    //         .on 'end', ->
    //           logger.emit 'end', "[#{id}] clientRequest"
    //
    //     .on 'error', (err) ->
    //       logger.emit 'error', "server\n#{escape err.stack}"
    //

    }

  });

program.parse(process.argv);
