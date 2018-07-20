import program from "commander";
import Logger from "tmpl-log";

const logger = new Logger({ tab: 10, gutter: " " })
  .registerTag("b", ["bold"])
  .registerEvent("echo", "<b>echo");

program.version(require("../package.json").version);

program.command("echo <arg>").action(arg => {
  logger.emit("echo", `echoing "${arg}"`);
});

program.parse(process.argv);
