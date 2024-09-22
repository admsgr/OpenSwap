import { OperaFixtureType } from './shared/fixtures';

export type TestContext = OperaFixtureType & {
  subject?: Function;
};
