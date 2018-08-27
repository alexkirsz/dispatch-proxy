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

program.command('list')
  .description('list all available network interfaces')
  .action(function() {
    console.log("listing interfaces:");
    console.log(OS.networkInterfaces());
  });


program.parse(process.argv);
