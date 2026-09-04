"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateEscrowDelay = exports.modifyTrustedContacts = exports.addDemoFunds = exports.unlinkFromGuardian = exports.linkAccounts = exports.createPairingSession = exports.denyTransfer = exports.approveTransfer = exports.settleTransfers = exports.cancelTransfer = exports.createTransfer = void 0;
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// Transfers
var createTransfer_1 = require("./transfers/createTransfer");
Object.defineProperty(exports, "createTransfer", { enumerable: true, get: function () { return createTransfer_1.createTransfer; } });
var cancelTransfer_1 = require("./transfers/cancelTransfer");
Object.defineProperty(exports, "cancelTransfer", { enumerable: true, get: function () { return cancelTransfer_1.cancelTransfer; } });
var settleTransfers_1 = require("./transfers/settleTransfers");
Object.defineProperty(exports, "settleTransfers", { enumerable: true, get: function () { return settleTransfers_1.settleTransfers; } });
// Guardian
var approveTransfer_1 = require("./guardian/approveTransfer");
Object.defineProperty(exports, "approveTransfer", { enumerable: true, get: function () { return approveTransfer_1.approveTransfer; } });
var denyTransfer_1 = require("./guardian/denyTransfer");
Object.defineProperty(exports, "denyTransfer", { enumerable: true, get: function () { return denyTransfer_1.denyTransfer; } });
// Pairing
var createPairingSession_1 = require("./pairing/createPairingSession");
Object.defineProperty(exports, "createPairingSession", { enumerable: true, get: function () { return createPairingSession_1.createPairingSession; } });
var linkAccounts_1 = require("./pairing/linkAccounts");
Object.defineProperty(exports, "linkAccounts", { enumerable: true, get: function () { return linkAccounts_1.linkAccounts; } });
Object.defineProperty(exports, "unlinkFromGuardian", { enumerable: true, get: function () { return linkAccounts_1.unlinkFromGuardian; } });
// Settings
var settingsCallables_1 = require("./settings/settingsCallables");
Object.defineProperty(exports, "addDemoFunds", { enumerable: true, get: function () { return settingsCallables_1.addDemoFunds; } });
Object.defineProperty(exports, "modifyTrustedContacts", { enumerable: true, get: function () { return settingsCallables_1.modifyTrustedContacts; } });
Object.defineProperty(exports, "updateEscrowDelay", { enumerable: true, get: function () { return settingsCallables_1.updateEscrowDelay; } });
//# sourceMappingURL=index.js.map