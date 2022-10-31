import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import fax from '../compiled/fax.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = process.env.RPC; //"http://127.0.0.1:8732"
const pk: string = process.env.ADMIN_PK || undefined;
const Tezos = new TezosToolkit(rpc);

let fax_address = process.env.FAX_CONTRACT_ADDRESS || undefined;


async function orig() {

    let fax_store = {
        printers: new MichelsonMap(),
        account_balances: new MichelsonMap(),
        max_printer_size: 100, // 100 jobs per printer is already quite a lot
    }

    try {
        // Originate an Fax contract
        const signer = await InMemorySigner.fromSecretKey(
            pk
        );

        Tezos.setProvider({ signer: signer })
        // Originate an Fax contract
        if (fax_address === undefined) {
            const fax_originated = await Tezos.contract.originate({
                code: fax,
                storage: fax_store,
            })
            console.log(`Waiting for FAX ${fax_originated.contractAddress} to be confirmed...`);
            await fax_originated.confirmation(2);
            console.log('confirmed FAX: ', fax_originated.contractAddress);
            fax_address = fax_originated.contractAddress;              
        }
       
        console.log("./tezos-client remember contract FAX", fax_address)
        // console.log("tezos-client transfer 0 from ", admin, " to ", advisor_address, " --entrypoint \"executeAlgorithm\" --arg \"Unit\"")

    } catch (error: any) {
        console.log(error)
        return process.exit(1)
    }
}

orig();
