import * as admin from "firebase-admin";

admin.initializeApp();

// Transfers
export { createTransfer } from "./transfers/createTransfer";
export { cancelTransfer } from "./transfers/cancelTransfer";
export { settleTransfers } from "./transfers/settleTransfers";

// Guardian
export { approveTransfer } from "./guardian/approveTransfer";
export { denyTransfer } from "./guardian/denyTransfer";

// Pairing
export { createPairingSession } from "./pairing/createPairingSession";
export { linkAccounts, unlinkFromGuardian } from "./pairing/linkAccounts";

// Settings
export { 
    addDemoFunds, 
    modifyTrustedContacts, 
    updateEscrowDelay 
} from "./settings/settingsCallables";
