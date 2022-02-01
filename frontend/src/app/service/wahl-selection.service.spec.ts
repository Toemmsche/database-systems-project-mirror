import { TestBed } from '@angular/core/testing';

import { WahlSelectionService } from './wahl-selection.service';

describe('WahlSelectionService', () => {
  let service: WahlSelectionService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(WahlSelectionService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
