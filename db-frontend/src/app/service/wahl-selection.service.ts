import {Injectable} from '@angular/core';
import {BehaviorSubject, Observable, Subject} from "rxjs";

@Injectable({
  providedIn: 'root'
})
export class WahlSelectionService {
  @Injectable()
  is2017$: Observable<boolean>;

  wahlSubject: BehaviorSubject<boolean>;

  constructor() {
    this.wahlSubject = new BehaviorSubject<boolean>(false);
    this.is2017$ = this.wahlSubject.asObservable();
  }
}
