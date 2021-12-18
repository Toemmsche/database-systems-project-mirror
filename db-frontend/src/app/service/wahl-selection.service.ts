import {Injectable} from '@angular/core';
import {BehaviorSubject} from "rxjs";

@Injectable({
  providedIn: 'root'
})
export class WahlSelectionService {
  wahlSubject: BehaviorSubject<number>;

  constructor() {
    this.wahlSubject = new BehaviorSubject<number>(1);
  }

  getWahlNumber(wahl: number): number {
    switch (wahl) {
      case 0: return 19;
      case 1: return 20;
      default: throw new Error('Invalid Wahl selection');
    }
  }
}
