import { ComponentFixture, TestBed } from '@angular/core/testing';

import { WahlkreissiegerComponent } from './wahlkreissieger.component';

describe('WahlkreissiegerComponent', () => {
  let component: WahlkreissiegerComponent;
  let fixture: ComponentFixture<WahlkreissiegerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ WahlkreissiegerComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(WahlkreissiegerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
