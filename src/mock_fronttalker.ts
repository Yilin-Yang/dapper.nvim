import {BasicFrontTalker} from './basic_fronttalker';
import {DapperAnyMsg} from './messages';

/**
 * FrontTalker implementation for use in test cases.
 */
export class MockFrontTalker extends BasicFrontTalker {
  private lastMessage: DapperAnyMsg|undefined;

  constructor() {
    super();
    this.lastMessage = undefined;
  }

  send(msg: DapperAnyMsg): void {
    // deep copy outgoing message
    this.lastMessage = JSON.parse(JSON.stringify(msg));
  }

  getLast(): DapperAnyMsg|undefined {
    return JSON.parse(JSON.stringify(this.lastMessage));
  }
}
