import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BundeslandlisteComponent } from './bundeslandliste.component';

describe('BundeslandlisteComponent', () => {
  let component: BundeslandlisteComponent;
  let fixture: ComponentFixture<BundeslandlisteComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ BundeslandlisteComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(BundeslandlisteComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
