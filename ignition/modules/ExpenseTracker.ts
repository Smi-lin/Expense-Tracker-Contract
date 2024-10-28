import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ExpenseTrackerModule = buildModule("ExpenseTrackerModule", (c) => {
  const expenseTracker = c.contract("ExpenseTracker");

  return { expenseTracker };
});

export default ExpenseTrackerModule;

// ExpenseTrackerModule#ExpenseTracker - 0xAE59e30755093436A917E074CBdBFE67f7FeD2c1

//  https://sepolia.basescan.org/address/0xb8fa5A6Af94F58181b1Cbb5a369fdad94D468D21#code