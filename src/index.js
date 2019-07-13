import program from "commander";
import Logger from "tmpl-log";
import OS from "os";

const logger = new Logger({ tab: 10, gutter: " " })
  .registerTag("b", ["bold"])
  .registerEvent("echo", "<b>echo");

program.version(require("../package.json").version);

program.command("echo <arg>").action(arg => {
  logger.emit("echo", `echoing "${arg}"`);
});

program
  .command('list')
  .description('list all available network interfaces')
  .action(function() {
    const interfaces = OS.networkInterfaces();
    console.log("listing interfaces:\n");

    for (let name in interfaces) {
      logger.log (`<b> ${name}`);

      for (let i = 0; i < interfaces[name].length; i++) {
        let subInterface = interfaces[name][i];
        let subInterfaceAddress = interfaces[name][i].adress;

        let { address, family, internal } = subInterface;
        if (internal === true) {
          internal = 'Internal';
        } else internal = 'External';
        logger.log (`     ${address} (${family}, ${internal})\n`);

      }
    }
  });


program.parse(process.argv);
