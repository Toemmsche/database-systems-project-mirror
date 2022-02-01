import { ComponentFixture, TestBed } from '@angular/core/testing';

import { WahlkreislisteComponent } from './wahlkreisliste.component';

describe('WahlkreislisteComponent', () => {
  let component: WahlkreislisteComponent;
  let fixture: ComponentFixture<WahlkreislisteComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ WahlkreislisteComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(WahlkreislisteComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
