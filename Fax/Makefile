ligo_compiler?=docker run --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:stable
# ^ Override this variable when you run make command by make <COMMAND> ligo_compiler=<LIGO_EXECUTABLE>
# ^ Otherwise use default one (you'll need docker)
protocol_opt?=
JSON_OPT?=--michelson-format json
tsc=npx tsc
help:
	@echo  'Usage:'
	@echo  '  all             - Remove generated Michelson files, recompile smart contracts and lauch all tests'
	@echo  '  clean           - Remove generated Michelson files'
	@echo  '  compile         - Compiles smart contract Fax'
	@echo  '  test            - Run integration tests (written in Ligo)'
	@echo  '  deploy          - Deploy smart contract Fax (typescript using Taquito)'
	@echo  ''

all: clean compile test

compile: fax

fax: fax.tz fax.json

fax.tz: contracts/main.mligo
	@if [ ! -d ./compiled ]; then mkdir ./compiled ; fi
	@echo "Compiling smart contract to Michelson"
	@$(ligo_compiler) compile contract $^ -e main $(protocol_opt) > compiled/$@

fax.json: contracts/main.mligo
	@if [ ! -d ./compiled ]; then mkdir ./compiled ; fi
	@echo "Compiling smart contract to Michelson in JSON format"
	@$(ligo_compiler) compile contract $^ $(JSON_OPT) -e main $(protocol_opt) > compiled/$@

clean:
	@echo "Removing Michelson files"
	@rm -f compiled/*.tz compiled/*.json

test: test_ligo_registration test_ligo_print

test_ligo_registration: test/test_registration.mligo
	@echo "Running integration tests (registration)"
	@$(ligo_compiler) run test $^ $(protocol_opt)

test_ligo_print: test/test_print.mligo
	@echo "Running integration tests (fax print)"
	@$(ligo_compiler) run test $^ $(protocol_opt)

deploy: node_modules deploy.js
	@echo "Deploying contract"
	@node deploy/deploy.js

deploy.js:
	@@if [ ! -f ./deploy/metadata.json ]; then cp deploy/metadata.json.dist \
        deploy/metadata.json ; fi
	@cd deploy && $(tsc) deploy.ts --resolveJsonModule -esModuleInterop

node_modules:
	@echo "Install node modules"
	@cd deploy && npm install
