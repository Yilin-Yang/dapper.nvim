import {BasicFrontTalker} from './basic_fronttalker';
import {DapperAnyMsg} from './messages';

/**
 * FrontTalker implementation for use in test cases.
 */
export class MockFrontTalker extends BasicFrontTalker {
  private messages: DapperAnyMsg[]|undefined;

  constructor() {
    super();
    this.messages = undefined;
  }

  send(msg: DapperAnyMsg): void {
    // deep copy outgoing message
    if (!this.messages) {
      this.messages = [];
    }
    this.messages.push(JSON.parse(JSON.stringify(msg)));
  }

  getLast(): DapperAnyMsg|undefined {
    if (!this.messages) return undefined;
    return JSON.parse(JSON.stringify(this.messages[this.messages.length - 1]));
  }

  hasReceived(typename: string): boolean {
    if (!this.messages) return false;
    const msgs = this.messages;
    for (let i = 0; i < msgs.length; ++i) {
      const msg = msgs[i];
      if (msg.vim_msg_typename === typename) return true;
    }
    return false;
  }

  reset(): void {
    this.messages = undefined;
  }
}
