import {BasicFrontTalker} from './basic_fronttalker';
import {DapperAnyMsg, DapperReport, typenameOf} from './messages';

// tslint:disable:no-any

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

  report(kind: string, brief: string, long: string, other?: any):
      Promise<void> {
    if (!this.messages) {
      this.messages = [];
    }
    const msg: DapperReport = {
      seq: 0,
      vim_id: 0,
      vim_msg_typename: '',
      type: 'report',
      kind,
      brief,
      long,
      other
    };
    msg.vim_msg_typename = typenameOf(msg);
    this.messages.push(msg);
    console.log(kind + ' report: ' + brief);
    console.log('long: ' + JSON.stringify(long));
    if (other) {
      console.log('other: ' + JSON.stringify(other));
    }
    return Promise.resolve();
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
