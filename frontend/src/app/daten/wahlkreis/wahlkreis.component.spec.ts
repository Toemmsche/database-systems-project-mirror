import { ComponentFixture, TestBed } from '@angular/core/testing';

import { WahlkreisComponent } from './wahlkreis.component';

describe('WahlkreisComponent', () => {
  let component: WahlkreisComponent;
  let fixture: ComponentFixture<WahlkreisComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ WahlkreisComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(WahlkreisComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
